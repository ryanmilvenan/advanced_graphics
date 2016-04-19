////
////  Node.swift
////  AdvancedGraphicsProject
////
////  Created by Mountain on 4/13/16.
////  Copyright © 2016 Ryan Milvenan. All rights reserved.
////
//
//import Foundation
//import Metal
//import MetalKit
//import QuartzCore
//import GLKit
//
//class Node {
//    
//    let name: String
//    var vertexCount: Int
//    var vertexBuffer: MTLBuffer
//    var device: MTLDevice
//    var position: GLKVector3
//    var rotateX:Float
//    var rotateY:Float
//    var rotateZ:Float
//    var scale:Float
//    var children:[Node]
//    
//    init(name: String, vertices: Array<Vertex>, device: MTLDevice){
//        // 1
//        var vertexData = Array<Float>()
//        for vertex in vertices{
//            vertexData += vertex.floatBuffer()
//        }
//        
//        // 2
//        let dataSize = vertexData.count * sizeofValue(vertexData[0])
//        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: [])
//        
//        // 3
//        self.name = name
//        self.device = device
//        vertexCount = vertices.count
//    }
//    
//    func modelMatrix() -> GLKMatrix4 {
//        var modelMatrix:GLKMatrix4 = GLKMatrix4Identity
//        modelMatrix = GLKMatrix4Translate(modelMatrix, self.position.x, self.position.y, self.position.z)
//        modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotateX, 1, 0, 0)
//        modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotateY, 0, 1, 0)
//        modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotateZ, 0, 0, 1)
//        modelMatrix = GLKMatrix4Scale(modelMatrix, self.scale, self.scale, self.scale)
//        
//        return modelMatrix
//    }
//    
//    func renderWithParentModelViewMatrix(parentModelViewMatrix:GLKMatrix4, commandBuffer:MTLCommandBuffer, pipelineState:MTLRenderPipelineState, renderPassDescriptor:MTLRenderPassDescriptor, drawable:CAMetalDrawable) {
//        
//        let modelViewMatrix:GLKMatrix4 = GLKMatrix4Multiply(parentModelViewMatrix, modelMatrix())
//        
//        //If it looks weird try moving this...
//        for node in self.children {
//            node.renderWithParentModelViewMatrix(modelViewMatrix, commandBuffer: commandBuffer, pipelineState: pipelineState, renderPassDescriptor:renderPassDescriptor, drawable: drawable)
//        }
//        
//        //Assign texture
//        
//        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
//        renderEncoder.setRenderPipelineState(pipelineState)
//        renderEncoder.setVertexBuffer(vertexBuffer, offset:0, atIndex:0)
//        
//        if let renderEncoder = renderEncoderOpt {
//            renderEncoder.setRenderPipelineState(pipelineState)
//            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
//            renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: vertexCount/3)
//            renderEncoder.endEncoding()
//        }
//        
//        commandBuffer.presentDrawable(drawable)
//        commandBuffer.commit()    }
//    
//    
//    
//}
//    
//    
//    
//    - (GLKMatrix4)modelMatrix {
//        GLKMatrix4 modelMatrix = GLKMatrix4Identity;
//        modelMatrix = GLKMatrix4Translate(modelMatrix, self.position.x, self.position.y, self.position.z);
//        modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotateX, 1, 0, 0);
//        modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotateY, 0, 1, 0);
//        modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotateZ, 0, 0, 1);
//        modelMatrix = GLKMatrix4Scale(modelMatrix, self.scale, self.scale, self.scale);
//        
//        return modelMatrix;
//        }
//        
//        - (void)renderWithParentModelViewMatrix:(GLKMatrix4)parentModelViewMatrix {
//            
//            GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(parentModelViewMatrix, [self modelMatrix]);
//            
//            for (Node *child in self.children) {
//                [child renderWithParentModelViewMatrix:modelViewMatrix];
//            }
//            
//            _shader.modelViewMatrix = modelViewMatrix;
//            _shader.texture = self.texture;
//            [_shader useProgram];
//            
//            glBindVertexArrayOES(_vao);
//            glDrawArrays(GL_TRIANGLES, 0, _vertexCount);
//            glBindVertexArrayOES(0);
//            }
//            
//            - (void)updateWithDelta:(NSTimeInterval)dt {
//                for (Node *child in self.children) {
//                    [child updateWithDelta:dt];
//                }
//                }
//                
//                - (void)loadTexture:(NSString *)filename {
//                    NSError *error;
//                    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
//                    
//                    NSDictionary *options = @{ GLKTextureLoaderOriginBottomLeft: @YES};
//                    GLKTextureInfo *info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
//                    if (info == nil) {
//                        NSLog(@"Error loading file: %@", error.localizedDescription);
//                    } else {
//                        self.texture = info.name;
//                    }
//}