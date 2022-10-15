public enum RenderingMeasurement: String, Hashable {
  case waitForRenderPassDescriptor
  case waitForOffscreenRenderPassDescriptor
  case updateCamera
  case createRenderCommandEncoder

  case world
  case updateWorldMesh
  case updateAnimatedTextures
  case encodeOpaque
  case encodeBlockOutline
  case encodeTranslucent

  case entities
  case getEntities
  case createUniforms
  case getBuffer

  case gui
  case updateUniforms
  case updateContent
  case createMeshes
  
  case onscreen
  case updateRenderTarget
  case encodeUpscale

  case encode

  case commitToGPU
}
