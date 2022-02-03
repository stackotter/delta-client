import Foundation

public protocol ChatComponent {
  var style: ChatStyle { get set }
  var siblings: [ChatComponent] { get set }
  
  init(from json: JSON, locale: MinecraftLocale) throws
  
  func toText() -> String
}
