import Foundation

public enum MinecraftLocaleError: LocalizedError {
  case unableToParseLocale
}

public struct MinecraftLocale {
  var translations: [String: String]
  
  public init() {
    self.translations = [:]
  }
  
  public init(localeFile: URL) throws {
    do {
      let data = try Data(contentsOf: localeFile)
      if let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String] {
        self.translations = dict
        return
      }
    } catch {
      log.warning("failed to parse locale `\(localeFile.lastPathComponent)`")
      throw error
    }
    throw MinecraftLocaleError.unableToParseLocale
  }
  
  public func getTranslation(for key: String, with content: [String]) -> String {
    let template = getTemplate(for: key)
    return format(template: template, strings: content)
  }
  
  public func getTemplate(for key: String) -> String {
    if let template = translations[key] {
      return template
    } else {
      return key
    }
  }
  
  // the locales use %s formats but swift doesn't like that so here's a bunch of unsafe pointers and cstrings for you
  
  private func format(template: String, strings: [String]) -> String {
    var cStrings: [UnsafePointer<Int8>] = []
    return format(template: template, strings: strings, currentIndex: 0, cStrings: &cStrings)
  }
  
  private func format(template: String, strings: [String], currentIndex: Int, cStrings: inout [UnsafePointer<Int8>]) -> String {
    if strings.count != currentIndex {
      let string = strings[currentIndex]
      let out: String = string.withCString {
        cStrings.append($0)
        let out = format(template: template, strings: strings, currentIndex: currentIndex + 1, cStrings: &cStrings)
        return out
      }
      return out
    } else {
      return String(format: template, arguments: cStrings)
    }
  }
}
