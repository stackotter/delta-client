import Foundation

/// An entity model represented in the standard JSON Entity Model format (from `.jem` files).
public struct JSONEntityModel: Codable {
  public var textureSize: Vec2f
  public var models: [Submodel]

  public struct Submodel: Codable {
    public var part: String?
    public var id: String?
    public var invertAxis: String?
    public var mirrorTexture: String?
    /// Translation to apply post-rotation (ignored if ``rotate`` is `nil`).
    public var translate: Vec3f?
    /// Rotation in degrees.
    public var rotate: Vec3f?
    public var boxes: [Box]?
    public var submodels: [Submodel]?
    public var animations: [[String: Either<String, Int>]]?
  }

  public struct Box: Codable {
    public var coordinates: [Float]
    public var textureOffset: Vec2i?
    public var uvNorth: Vec4i?
    public var uvEast: Vec4i?
    public var uvSouth: Vec4i?
    public var uvWest: Vec4i?
    public var uvUp: Vec4i?
    public var uvDown: Vec4i?
    public var sizeAdd: Float?
  }

  /// Loads all JSON Entity Models from
  public static func loadModels(
    from directory: URL,
    namespace: String
  ) throws -> [Identifier: JSONEntityModel] {
    let files = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: .skipsSubdirectoryDescendants
    )

    var models: [Identifier: JSONEntityModel] = [:]
    for file in files where file.pathExtension == "jem" {
      let identifier = Identifier(
        namespace: namespace,
        name: file.deletingPathExtension().lastPathComponent
      )

      let model: JSONEntityModel
      do {
        let data = try Data(contentsOf: file)
        model = try CustomJSONDecoder().decode(JSONEntityModel.self, from: data)
      } catch {
        throw EntityModelPaletteError.failedToDeserializeJSONEntityModel(file, error)
      }
      models[identifier] = model
    }

    return models
  }
}
