/// A custom format string formatter than can handle format specifiers of the format "%s" or "%x$s"
/// where x is a substitution index starting from 1. This is used by the Minecraft localization
/// mechanism to generate localized strings from templates.
public struct LocalizationFormatter {
  var substitutions: [String]

  var currentSubstitutionIndex = 0
  var isInFormatSpecifier = false
  var currentFormatSpecifier = ""
  var specifiedSubstitutionIndex: Int?

  var output = ""

  public static func format(_ template: String, withSubstitutions substitutions: [String]) -> String {
    var formatter = LocalizationFormatter(substitutions: substitutions)
    for character in template {
      formatter.update(character)
    }
    formatter.finish()
    return formatter.output
  }

  private init(substitutions: [String]) {
    self.substitutions = substitutions
  }

  private mutating func update(_ character: Character) {
    if isInFormatSpecifier {
      let alreadyContainsDollarSymbol = currentFormatSpecifier.contains("$")
      currentFormatSpecifier.append(character)

      if character == "%" {
        // "%%" should result in "%"
        output += "%"
        endFormatSpecifier()
      } else if character == "s" {
        // "s" always ends a substitution
        handleSubstitution()
      } else if alreadyContainsDollarSymbol {
        // "$" should always be immediately followed by "s"
        output += currentFormatSpecifier
        endFormatSpecifier()
      } else if let digit = Int(String(character)) {
        // Format specifiers can include an index immediately following the "%"
        if let index = specifiedSubstitutionIndex {
          specifiedSubstitutionIndex = index * 10 + digit
        } else {
          specifiedSubstitutionIndex = digit
        }
      } else if character == "$" {
        // "$" should always be preceded by a substitution index
        if specifiedSubstitutionIndex == nil {
          output += currentFormatSpecifier
          endFormatSpecifier()
        }
      } else {
        // Invalid format specifier, just include in the output and move on
        output += currentFormatSpecifier
        endFormatSpecifier()
      }
    } else {
      if character == "%" {
        beginFormatSpecifier()
      } else {
        output += String(character)
      }
    }
  }

  private mutating func finish() {
    output += currentFormatSpecifier
  }

  private mutating func beginFormatSpecifier() {
    isInFormatSpecifier = true
    currentFormatSpecifier = "%"
  }

  private mutating func endFormatSpecifier() {
    isInFormatSpecifier = false
    currentFormatSpecifier = ""
    specifiedSubstitutionIndex = nil
  }

  private mutating func handleSubstitution() {
    var index: Int
    if let specifiedSubstitutionIndex = specifiedSubstitutionIndex {
      // Indices specified in format specifiers start at 1
      index = specifiedSubstitutionIndex - 1
    } else {
      index = currentSubstitutionIndex
      currentSubstitutionIndex += 1
    }

    if index < substitutions.count {
      output += substitutions[index]
    } else {
      output += currentFormatSpecifier
    }

    endFormatSpecifier()
  }
}
