public enum RenderingMeasurement: String, Hashable {
  case waitForRenderPassDescriptor
  case updateCamera
  case createRenderCommandEncoder

  case world
  case updateWorldMesh
  case updateAnimatedTextures
  case encodeOpaque
  case encodeTranslucent

  case entities
  case getEntities
  case createUniforms
  case getBuffer

  case gui
  case updateUniforms
  case updateContent
  case createMeshes

  case encode

  case commitToGPU
}
