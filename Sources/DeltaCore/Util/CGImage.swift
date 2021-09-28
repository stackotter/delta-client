//
//  CGImage.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 16/7/21.
//

import Foundation

extension CGImage {
  public func getBytes(with colorSpace: CGColorSpace, and bitmapInfo: UInt32, scaledBy scaleFactor: Int) throws -> [UInt8] {
    let scaledWidth = width * scaleFactor
    let scaledHeight = height * scaleFactor
    
    let bitsPerComponent = 8
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * scaledWidth
    
    // Create context to draw into
    guard let context = CGContext(
      data: nil,
      width: scaledWidth,
      height: scaledHeight,
      bitsPerComponent: bitsPerComponent,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ) else {
      throw TextureError.failedToCreateContext
    }
    
    // Draw the image into the context
    let rect = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
    context.interpolationQuality = .none // Nearest neighbour
    context.clear(rect)
    context.draw(self, in: rect)
    context.flush()
    
    // Get the bytes of the context
    guard let bytes = context.data else {
      throw TextureError.failedToGetContextBytes
    }
    
    // Convert the bytes from a pointer to an array of UInt8
    let buffer = UnsafeBufferPointer(start: bytes.assumingMemoryBound(to: UInt8.self), count: scaledWidth * scaledHeight * bytesPerPixel)
    return Array(buffer)
  }
}
