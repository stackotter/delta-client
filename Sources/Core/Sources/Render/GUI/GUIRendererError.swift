import Foundation

/// An error thrown by ``GUIRenderer``.
enum GUIRendererError: LocalizedError {
  case failedToCreateVertexBuffer
  case failedToCreateIndexBuffer
  case failedToCreateUniformsBuffer
  case failedToCreateCharacterUniformsBuffer
  case emptyText
  case invalidCharacter(Character)
  case invalidItemId(Int)
  case missingItemTexture(Int)
  case failedToCreateTextMeshBuffer

  var errorDescription: String? {
    switch self {
      case .failedToCreateVertexBuffer:
        return "Failed to create vertex buffer"
      case .failedToCreateIndexBuffer:
        return "Failed to create index buffer"
      case .failedToCreateUniformsBuffer:
        return "Failed to create uniforms buffer"
      case .failedToCreateCharacterUniformsBuffer:
        return "Failed to create character uniforms buffer"
      case .emptyText:
        return "Text was empty"
      case .invalidCharacter(let character):
        return "The selected font does not include '\(character)'"
      case .invalidItemId(let id):
        return "No item exists with id \(id)"
      case .missingItemTexture(let id):
        return "Missing texture for item with id \(id)"
      case .failedToCreateTextMeshBuffer:
        return "Failed to create text mesh buffer"
    }
  }
}
