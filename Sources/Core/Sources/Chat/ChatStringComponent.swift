import Foundation

struct ChatStringComponent: ChatComponent {
  var style: ChatStyle
  var siblings: [ChatComponent]
  
  var text: String
  
  init(from json: JSON, locale: MinecraftLocale) throws {
    guard let text = json.getString(forKey: "text") else {
      throw ChatError.noTextForStringComponent
    }
    self.text = text
    
    siblings = try ChatComponentUtil.readSiblings(json, locale: locale)
    style = ChatComponentUtil.readStyles(json)
  }
  
  init(fromString string: String) {
    text = string
    style = ChatStyle()
    siblings = []
  }
  
  func toText() -> String {
    var output = text
    for sibling in siblings {
      output += sibling.toText()
    }
    return output
  }
}
