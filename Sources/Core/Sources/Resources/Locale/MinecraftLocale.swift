import Foundation

public enum MinecraftLocaleError: LocalizedError {
  case unableToParseLocale

  public var errorDescription: String? {
    switch self {
      case .unableToParseLocale:
        return "Unable to parse locale."
    }
  }
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
    return LocalizationFormatter.format(template, withSubstitutions: content)
  }

  public func getTemplate(for key: String) -> String {
    if let template = translations[key] {
      return template
    } else {
      return key
    }
  }
}
