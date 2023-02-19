extension Unicode.Scalar {
  var isPrintable: Bool {
    switch properties.generalCategory {
      case .closePunctuation, .connectorPunctuation, .currencySymbol, .dashPunctuation, .decimalNumber, .enclosingMark, .finalPunctuation, .initialPunctuation, .letterNumber, .lineSeparator, .lowercaseLetter, .mathSymbol, .modifierLetter, .modifierSymbol, .nonspacingMark, .openPunctuation, .otherLetter, .otherNumber, .otherPunctuation, .otherSymbol, .paragraphSeparator, .spaceSeparator, .spacingMark, .titlecaseLetter, .uppercaseLetter:
        return true
      default:
        return false
    }
  }
}

extension Character {
  var isPrintable: Bool {
    return unicodeScalars.contains(where: { $0.isPrintable })
  }
}
