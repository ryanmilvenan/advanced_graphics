//
//  TextureLoader.swift
//  AdvancedGraphicsProject
//
//  Created by Mountain on 4/10/16.
//  Copyright © 2016 Ryan Milvenan. All rights reserved.
//

import Metal
import UIKit
import Foundation

class TextureLoader {
    static let sharedInstance = TextureLoader()
    private init() {}
    
    func texture2D(name:String, mipmapped:Bool, device:MTLDevice) -> MTLTexture {
        let image:UIImage = UIImage(imageLiteral:name)
        let imageSize:CGSize = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale)
        let bytesPerPixel:Int = 4
        let bytesPerRow:Int = bytesPerPixel * Int(imageSize.width)
        
        let imageData:UnsafeMutablePointer<Void> = self.dataForImage(image)
        
        let textureDescriptor:MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: Int(imageSize.width), height: Int(imageSize.height), mipmapped: mipmapped)
        
        let texture:MTLTexture = device.newTextureWithDescriptor(textureDescriptor)
        texture.label = name
        
        let region:MTLRegion = MTLRegionMake2D(0, 0, Int(imageSize.width), Int(imageSize.height))
        texture.replaceRegion(region, mipmapLevel: 0, withBytes: imageData, bytesPerRow: bytesPerRow)
        
        free(imageData)
        
        if(mipmapped) {
            self.generateMipmapsForTexture(texture)
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