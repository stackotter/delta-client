import Foundation

/// The structure of a block model as read from a resource pack.
public struct JSONBlockModel: Codable {
  /// The identifier of the parent of this block model.
  public var parent: Identifier?
  /// Whether to use ambient occlusion or not.
  public var ambientOcclusion: Bool?
  /// Transformations to use when displaying this block in certain situations.
  public var display: JSONBlockModelDisplay?
  /// Texture variables used in this block model.
  public var textures: [String: String]?
  /// The elements that make up this block model.
  public var elements: [JSONBlockModelElement]?
  
  enum CodingKeys: String, CodingKey {
    case parent
    case ambientOcclusion = "ambientocclusion"
    case display
    case textures
    case elements
  }
}

extension JSONBlockModel {
  /// Loads the json formatted block models from the given directory.
  public static func loadModels(
    from directory: URL,
    namespace: String
  ) throws -> [Identifier: JSONBlockModel] {
    var mojangBlockModels: [Identifier: JSONBlockModel] = [:]
    
    let files = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: .skipsSubdirectoryDescendants)
    for file in files where file.pathExtension == "json" {
      let blockName = file.deletingPathExtension().lastPathComponent
      let identifier = Identifier(namespace: namespace, name: "block/\(blockName)")
      let data = try Data(contentsOf: file)
      let mojangBlockModel = try JSONDecoder().decode(JSONBlockModel.self, from: data)
      mojangBlockModels[identifier] = mojangBlockModel
    }
    
    return mojangBlockModels
  }
}
