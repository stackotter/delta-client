import Foundation
import FirebladeMath

extension Mat4x4f {
  func data() -> Data {
    var mutableColumns = columns
    let data = Data(
      bytes: &mutableColumns,
      count: MemoryLayout<Mat4x4f.Vector>.stride * 4
    )
    return data
  }

  init(from data: Data) throws {
    guard data.count == MemoryLayout<Mat4x4f.Vector>.stride * 4 else {
      throw BlockModelPaletteError.invalidMatrixDataLength(data.count)
    }

    let vectors: (Mat4x4f.Vector, Mat4x4f.Vector, Mat4x4f.Vector, Mat4x4f.Vector) = data.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
      let pointer = pointer.bindMemory(to: Mat4x4f.Vector.self)
      return (
        pointer[0],
        pointer[1],
        pointer[2],
        pointer[3]
      )
    }

    self.init(vectors.0, vectors.1, vectors.2, vectors.3)
  }
}
