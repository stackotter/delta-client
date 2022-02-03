import Foundation
import ZippyJSON

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
    // Constants used when composing JSON object from models
    let doubleQuote = "\"".data(using: .utf8)!
    let doubleQuoteColon = "\":".data(using: .utf8)!
    let comma = ",".data(using: .utf8)!
    
    // JSON object starts with opening brace
    var json = "{".data(using: .utf8)!
    
    // Reserves the approximate size of the block model folder of a vanilla resource pack (with a bit of head room).
    // Seems to cut down times by about 5 to 10%.
    json.reserveCapacity(540000)
    
    // Get list of all files in block model directory
    let files = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil,
      options: .skipsSubdirectoryDescendants)
    
    // All file reading operations are performed at once which is best for performance apparently
    // The models are combined into one big JSON object which should also minimise losses from
    // switching between Swift and ZippyJSON's cpp. It seems to cut down load time of the json
    // files by about 25% (from 780ms to 570ms). I wrote a rust program to do the same thing
    // (without the weird combining objects trick) and it can read and deserialize all of the files
    // in 55ms :'( I didn't even have to do any weird tricks or optimisations.
    var isFirst = true
    for file in files where file.pathExtension == "json" {
      // Add comma separator between model entries
      if isFirst {
        isFirst = false
      } else {
        json.append(comma)
      }
      
      let blockName = file.deletingPathExtension().lastPathComponent
      
      // Append `"blockName":`
      json.append(doubleQuote)
      json.append(blockName.data(using: .utf8)!)
      json.append(doubleQuoteColon)
      
      let data = try Data(contentsOf: file)
      
      // Append model JSON object
      json.append(data)
    }
    
    // Finish JSON object with a closing brace
    json.append("}".data(using: .utf8)!)
    
    // Load JSON
    let models: [String: JSONBlockModel] = try ZippyJSONDecoder().decode([String: JSONBlockModel].self, from: json)
    
    // Convert from [String: JSONBlockModel] to [Identifier: JSONBlockModel]
    var identifiedModels: [Identifier: JSONBlockModel] = [:]
    for (blockName, model) in models {
      let identifier = Identifier(namespace: namespace, name: "block/\(blockName)")
      identifiedModels[identifier] = model
    }
    
    return identifiedModels
  }
}
