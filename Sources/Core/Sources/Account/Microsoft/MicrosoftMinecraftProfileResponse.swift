import Foundation

public struct MicrosoftMinecraftProfileResponse: Decodable {
  public var id: String
  public var name: String
  public var skins: [Skin]
  public var capes: [Cape]?
  
  public struct Skin: Decodable {
    public var id: String
    public var state: String
    public var url: URL
    public var variant: String
    public var alias: String?
  }
  
  public struct Cape: Decodable {
    public var id: String
    public var state: String
    public var url: URL
    public var alias: String?
  }
}
