import Foundation
import FirebladeMath

extension Mat4x4f {
  func data() -> Data {
    var mutableSelf = self
    let data = Data(bytes: &mutableSelf, count: MemoryLayout<Mat4x4f>.size)
    return data
  }
  
  init(from data: Data) throws {
    guard data.count == 64 else { // 4 * 4 * 4
      throw BlockModelPaletteError.invalidMatrixDataLength(data.count)
    }
    
    self.init(scale: .one)
    var columns = self.columns
    _ = withUnsafeMutableBytes(of: &columns) {
      data.copyBytes(to: $0)
    }
  }
}
