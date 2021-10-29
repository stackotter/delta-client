import Foundation

public struct PluginMetadata: Codable {
  public let name: String
  public let version: String
  public let apiVersion: String
  public let dylibPath: String
  public let builderFunctionName: String
  
  public static let currentAPIVersion: String = "0.2.0"
}
