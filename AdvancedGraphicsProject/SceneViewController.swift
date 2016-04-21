//
//  GameViewController.swift
//  AdvancedGraphicsProject
//
//  Created by Wind on 3/20/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import UIKit
import Metal
import MetalKit
import GLKit
import CoreMotion
import simd

let MaxBuffers = 3
let ConstantBufferSize = 1024*1024


class SceneViewController:UIViewController, MTKViewDelegate {
    
    var device: MTLDevice! = nil
    
    let manager = CMMotionManager()
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var defaultLibrary: MTLLibrary! = nil
    var depthState: MTLDepthStencilState! = nil
    
    var scene:Node! = nil
    var frameUniformBuffers:[MTLBuffer] = []
    
    let inflightSemaphore = dispatch_semaphore_create(MaxBuffers)
    var bufferIndex = 0
    
    var projectionMatrix: float4x4 = float4x4(matrix_identity_float4x4)
    var viewMatrix: float4x4 = float4x4(matrix_identity_float4x4)
    var rotation: Float = 0
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.setupAccelerometer()
        self.setupMetal();
        self.setupView();
        self.loadAssets();
        self.reshape();
    }
    
    
    func view(view: MTKView, willLayoutWithSize size: CGSize) {
        reshape()
    }
    
    func setupAccelerometer() {
        if manager.accelerometerAvailable {
            manager.accelerometerUpdateInterval = 0.01
            manager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) {
                [weak self] (data: CMAccelerometerData?, error: NSError?) in
                if let acceleration = data?.acceleration {
                    self!.rotation = Float(acceleration.y)
                }
            }
        }
    }
    
    func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank UIView, an application could also fallback to OpenGL ES here.
            print("Metal is not supported on this device")
            self.view = UIView(frame: self.view.frame)
            return
        }
        
        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
        
        defaultLibrary = device.newDefaultLibrary()!
    }
    
    func setupView() {
        // setup view properties
        let view = self.view as! MTKView
        view.device = device
        view.delegate = self
        
        view.sampleCount = 4
        view.depthStencilPixelFormat = MTLPixelFormat.Depth32Float_Stencil8
    }
    
    func loadAssets() {
        
        // load any resources required for rendering
        let view = self.view as! MTKView

        let fragmentProgram = defaultLibrary.newFunctionWithName("fragmentShader")!
        let vertexProgram = defaultLibrary.newFunctionWithName("vertexShader")!
        
        let meshVertexBufferIdx:Int = BufferIndex.MeshVertexBuffer.rawValue
        
        //Position
        let mtlVertexDescriptor:MTLVertexDescriptor = MTLVertexDescriptor()
        let vertexAttributePosition:Int = VertexAttributes.VertexAttributePosition.rawValue
        mtlVertexDescriptor.attributes[vertexAttributePosition].format = MTLVertexFormat.Float3
        mtlVertexDescriptor.attributes[vertexAttributePosition].offset = 0
        mtlVertexDescriptor.attributes[vertexAttributePosition].bufferIndex = meshVertexBufferIdx
        
        //Normals
        let normalAttributePosition:Int = VertexAttributes.VertexAttributeNormal.rawValue
        mtlVertexDescriptor.attributes[normalAttributePosition].format = MTLVertexFormat.Float3
        mtlVertexDescriptor.attributes[normalAttributePosition].offset = 12
        mtlVertexDescriptor.attributes[normalAttributePosition].bufferIndex = meshVertexBufferIdx
        
        //Texture Coords
        let texcoordAttribute:Int = VertexAttributes.VertexAttributeTexcoord.rawValue
        mtlVertexDescriptor.attributes[texcoordAttribute].format = MTLVertexFormat.Half2
        mtlVertexDescriptor.attributes[texcoordAttribute].offset = 24
        mtlVertexDescriptor.attributes[texcoordAttribute].bufferIndex = meshVertexBufferIdx
        
        //Interleaved Buffer
        mtlVertexDescriptor.layouts[meshVertexBufferIdx].stride = 28
        mtlVertexDescriptor.layouts[meshVertexBufferIdx].stepRate = 1
        mtlVertexDescriptor.layouts[meshVertexBufferIdx].stepFunction = MTLVertexStepFunction.PerVertex
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Main Pipeline"
        pipelineStateDescriptor.sampleCount = view.sampleCount
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
        
        let depthStateDescriptor:MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = MTLCompareFunction.Less
        depthStateDescriptor.depthWriteEnabled = true
        depthState = device.newDepthStencilStateWithDescriptor(depthStateDescriptor)
        

        
        let sub = "models/minisub/minisub_data"
        
        scene = Sub(name: "Sub", device: device, assetPath: sub, vertexDescriptor: mtlVertexDescriptor)
        
        for _ in 0 ..< MaxBuffers {
            frameUniformBuffers.append(device.newBufferWithLength(
                sizeof(FrameUniforms),
                options: MTLResourceOptions.CPUCacheModeDefaultCache
                ))
        }
        
    }

    
    func updateSceneGeometry(frameData:FrameUniforms) {
        
    }
    
    func drawInMTKView(view: MTKView) {
        
        // use semaphore to encode 3 frames ahead
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER)
        
        let commandBuffer = commandQueue.commandBuffer()
        commandBuffer.label = "Frame command buffer"
        
        // use completion handler to signal the semaphore when this frame is completed allowing the encoding of the next frame to proceed
        // use capture list to avoid any retain cycles if the command buffer gets retained anywhere besides this stack frame
        commandBuffer.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                dispatch_semaphore_signal(strongSelf.inflightSemaphore)
            }
            return
        }
        
        if let renderPassDescriptor = view.currentRenderPassDescriptor, currentDrawable = view.currentDrawable
        {
            renderPassDescriptor.colorAttachments[0].loadAction = .Clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.3, 0.1, 0.3, 1)
            
            let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            renderEncoder.label = "render encoder"
            renderEncoder.setViewport(MTLViewport(
                originX: 0, originY: 0,
                width:  Double(view.drawableSize.width),
                height: Double(view.drawableSize.height),
                znear: 0, zfar: 1)
            )
            renderEncoder.setDepthStencilState(depthState)
            renderEncoder.setRenderPipelineState(pipelineState)
           
            renderEncoder.pushDebugGroup("Render Scene")
            scene.renderWithParentModelViewMatrix(viewMatrix, projectionMatrix: projectionMatrix, encoder: renderEncoder, frameBuffer:frameUniformBuffers, bufferIdx:bufferIndex)
            renderEncoder.popDebugGroup()
            renderEncoder.endEncoding()
                
            commandBuffer.presentDrawable(currentDrawable)
        }
        
        // bufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        bufferIndex = (bufferIndex + 1) % MaxBuffers
        
        commandBuffer.commit()
    }
    
    func reshape() {
        let aspect = fabsf(Float(CGRectGetWidth(view.bounds) / CGRectGetHeight(view.bounds)))
        projectionMatrix = matrixFromPerspectiveFOVAspectLH(
            fovY: Float(65 * M_PI / 180),
            aspect: aspect,
            nearZ: 0.1, farZ: 100
        )
        viewMatrix = float4x4(matrix_identity_float4x4)
    }
    
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
        reshape()
    }
}
