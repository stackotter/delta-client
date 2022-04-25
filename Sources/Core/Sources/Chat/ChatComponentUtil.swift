import Foundation

struct ChatComponentUtil {
  static func parseJSON(_ json: JSON, locale: MinecraftLocale) throws -> ChatComponent {
    if json.containsKey("text") {
      return try ChatStringComponent(from: json, locale: locale)
    } else if json.containsKey("translate") {
      return try ChatTranslateComponent(from: json, locale: locale)
    } else if json.containsKey("keybind") {
      return try ChatKeybindComponent(from: json, locale: locale)
    } else if json.containsKey("score") {
      return try ChatScoreComponent(from: json, locale: locale)
    } else {
      log.warning("invalid chat component json: \(json.dict)")
      throw ChatError.invalidJSON
    }
  }
  
  static func parseAny(_ object: Any, locale: MinecraftLocale) throws -> ChatComponent {
    if let string = object as? String {
      let component = ChatStringComponent(fromString: string)
      return component
    } else if let dict = object as? [String: Any] {
      let component = try ChatComponentUtil.parseJSON(JSON(dict: dict), locale: locale)
      return component
    } else if let array = object as? [Any] {
      var parent = try ChatComponentUtil.parseAny(array[0], locale: locale)
      parent.siblings = try readSiblingsArray(array: [Any](array.dropFirst()), locale: locale)
      return parent
    } else {
      log.warning("failed to ready chat component (invalid type)")
      throw ChatError.invalidComponentType
    }
  }
  
  static func readSiblings(_ json: JSON, locale: MinecraftLocale) throws -> [ChatComponent] {
    if let extra = json.getArray(forKey: "extra") {
      return try readSiblingsArray(array: extra, locale: locale)
    }
    return []
  }
  
  static func readSiblingsArray(array: [Any], locale: MinecraftLocale) throws -> [ChatComponent] {
    var siblings: [ChatComponent] = []
    for sibling in array {
      let component = try ChatComponentUtil.parseAny(sibling, locale: locale)
      siblings.append(component)
    }
    return siblings
  }
  
  static func readStyles(_ json: JSON) -> ChatStyle {
    return ChatStyle(from: json)
  }
}
