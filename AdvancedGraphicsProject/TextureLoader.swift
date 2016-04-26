//
//  TextureLoader.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/10/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Metal
import UIKit
import MetalKit
import Foundation

class TextureLoader {
    static let sharedInstance = TextureLoader()
    private init() {}
    
    func load2DTexture(path:String, mipmapped:Bool, device:MTLDevice) -> MTLTexture? {
        let fullPath:String = NSBundle.mainBundle().pathForResource(path, ofType: ".png")!
        let imgUrl = NSURL.fileURLWithPath(fullPath)
        let textureLoader:MTKTextureLoader = MTKTextureLoader.init(device: device)
        var texture:MTLTexture? = nil
        do {
            texture = try textureLoader.newTextureWithContentsOfURL(imgUrl, options:[MTKTextureLoaderOptionAllocateMipmaps:mipmapped])
        } catch {
            print("Could not load texture: \(path)")
        }
        
        if let tex = texture {
            if(mipmapped) {
                self.generateMipmapsForTexture(tex)
            }
        }
        
        return texture
    }
    
    func loadCubeTexture(images:[String], device:MTLDevice) -> MTLTexture {
        let firstImage:UIImage = UIImage.init(imageLiteral: images.first!)
        let cubeSize:CGFloat = firstImage.size.width * firstImage.scale
        
        let bytesPerPixel:Int = 4
        let bytesPerRow:Int = bytesPerPixel * Int(cubeSize)
        let bytesPerImage:Int = bytesPerRow * Int(cubeSize)
        
        let region:MTLRegion = MTLRegionMake2D(0, 0, Int(cubeSize), Int(cubeSize))
        let textureDescriptor:MTLTextureDescriptor = MTLTextureDescriptor.textureCubeDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, size: Int(cubeSize), mipmapped: false)
        
        let texture:MTLTexture = device.newTextureWithDescriptor(textureDescriptor)
        
        for slice in 0 ..< 6 {
            let imageName:String = images[slice]
            let image:UIImage = UIImage.init(imageLiteral: imageName)
            let imageData = self.dataForImage(image)
            
            texture.replaceRegion(region, mipmapLevel: 0, slice: slice, withBytes: imageData, bytesPerRow: bytesPerRow, bytesPerImage: bytesPerImage)
        }
        
        return texture
    }
    
    func dataForImage(image:UIImage) -> UnsafeMutablePointer<Void>{
        let imageRef:CGImageRef = image.CGImage!
        let width:Int = CGImageGetWidth(imageRef)
        let height:Int = CGImageGetHeight(imageRef)
        let colorSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
        let rawData:UnsafeMutablePointer<Void> = calloc(height * width * 4, sizeof(__uint8_t))
        let bytesPerPixel:Int = 4
        let bytesPerRow:Int = bytesPerPixel * width
        let bitsPerComponent:Int = 8
        let multLast = CGImageAlphaInfo.PremultipliedLast.rawValue
        let bitmapInfo = CGBitmapInfo(rawValue: multLast).union(.ByteOrder32Big)
        let context:CGContextRef = CGBitmapContextCreate(rawData, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue)!
        
        CGContextTranslateCTM(context, 0, CGFloat(height))
        CGContextScaleCTM(context, 1, -1)
        
        let imageRect:CGRect = CGRectMake(0, 0, CGFloat(width), CGFloat(height))
        CGContextDrawImage(context, imageRect, imageRef)
        
        return rawData
    }
    
    func generateMipmapsForTexture(texture:MTLTexture) {
        let device:MTLDevice = texture.device
        let commandQueue:MTLCommandQueue = device.newCommandQueue()
        let commandBuffer:MTLCommandBuffer = commandQueue.commandBuffer()
        let blitEncoder:MTLBlitCommandEncoder = commandBuffer.blitCommandEncoder()
        blitEncoder.generateMipmapsForTexture(texture)
        blitEncoder.endEncoding()
        commandBuffer.commit()
    }
}