import Foundation

struct ChatScoreComponent: ChatComponent {
  var style: ChatStyle
  var siblings: [ChatComponent]
  
  var name: String
  var objective: String
  var value: String
  
  init(from json: JSON, locale: MinecraftLocale) throws {
    guard
      let score = json.getJSON(forKey: "score"),
      let name = score.getString(forKey: "name"),
      let objective = score.getString(forKey: "objective"),
      let value = score.getString(forKey: "value")
    else {
      throw ChatError.failedToReadScoreComponent
    }
    
    self.name = name
    self.objective = objective
    self.value = value
    
    siblings = try ChatComponentUtil.readSiblings(json, locale: locale)
    style = ChatComponentUtil.readStyles(json)
  }
  
  func toText() -> String {
    var output = "\(name):\(objective):\(value)"
    for sibling in siblings {
      output += sibling.toText()
    }
    return output
  }
}
