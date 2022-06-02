import Foundation
import simd

extension matrix_float4x4 {
  func data() -> Data {
    var mutableSelf = self
    let data = Data(bytes: &mutableSelf, count: MemoryLayout<matrix_float4x4>.size)
    return data
  }
  
  init(from data: Data) throws {
    guard data.count == 64 else { // 4 * 4 * 4
      throw BlockModelPaletteError.invalidMatrixDataLength(data.count)
    }
    
    self.init()
    _ = withUnsafeMutableBytes(of: &self.columns) {
      data.copyBytes(to: $0)
    }
  }
}
