import Foundation

extension CGImage {
  public func getBytes(with colorSpace: CGColorSpace, and bitmapInfo: UInt32, scaledBy scaleFactor: Int = 1) throws -> [UInt8] {
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

// A really weird hack to wrap an optional initializer with a throwing one. https://stackoverflow.com/a/67781426
// Apparently it's the way the stdlib gets around this missing functionality too, so I guess it's the way

protocol CGImageFromPNGFile {
  init?(pngDataProviderSource: CGDataProvider, decode: UnsafePointer<CGFloat>?, shouldInterpolate: Bool, intent: CGColorRenderingIntent)
}

extension CGImage: CGImageFromPNGFile {}

extension CGImageFromPNGFile {
  init(pngFile: URL) throws {
    guard let dataProvider = CGDataProvider(url: pngFile as CFURL) else {
      throw ResourcePackError.failedToCreateImageProvider
    }
    
    guard let image = Self.init(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: false, intent: .relativeColorimetric) else {
      throw ResourcePackError.failedToReadTextureImage
    }
    
    self = image
  }
}
