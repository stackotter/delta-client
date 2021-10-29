import Foundation
import simd

struct CubeGeometry {
  static let faceWinding: [UInt32] = [0, 1, 2, 2, 3, 0]
  
  static let cubeVertices: [SIMD3<Float>] = [
    SIMD3<Float>([0, 1, 0]),
    SIMD3<Float>([0, 0, 0]),
    SIMD3<Float>([1, 0, 0]),
    SIMD3<Float>([1, 1, 0]),
    SIMD3<Float>([0, 1, 1]),
    SIMD3<Float>([0, 0, 1]),
    SIMD3<Float>([1, 0, 1]),
    SIMD3<Float>([1, 1, 1])]
  
  static let faceVertices: [Direction: [SIMD3<Float>]] = [
    .up: CubeGeometry.generateFaceVertices(facing: .up),
    .down: CubeGeometry.generateFaceVertices(facing: .down),
    .east: CubeGeometry.generateFaceVertices(facing: .east),
    .west: CubeGeometry.generateFaceVertices(facing: .west),
    .north: CubeGeometry.generateFaceVertices(facing: .north),
    .south: CubeGeometry.generateFaceVertices(facing: .south)]
  
  public static let shades: [Float] = [
    0.6, // down
    1.0, // up
    0.9, 0.9, // north, south
    0.7, 0.7  // east, west
  ]
  
  static func generateFaceVertices(facing: Direction) -> [SIMD3<Float>] {
    let vertexIndices: [Int]
    switch facing {
      case .up: vertexIndices = [3, 7, 4, 0]
      case .down: vertexIndices = [6, 2, 1, 5]
      case .east: vertexIndices = [3, 2, 6, 7]
      case .west: vertexIndices = [4, 5, 1, 0]
      case .north: vertexIndices = [0, 1, 2, 3]
      case .south: vertexIndices = [7, 6, 5, 4]
    }
    let vertices = vertexIndices.map { index in
      return cubeVertices[index]
    }
    return vertices
  }
}
