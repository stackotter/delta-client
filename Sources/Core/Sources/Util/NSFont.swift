import AppKit

extension NSFont {
  public func withTraits(_ traits: NSFontDescriptor.SymbolicTraits) -> NSFont? {
    let descriptor = fontDescriptor.withSymbolicTraits(traits)
    return NSFont(descriptor: descriptor, size: pointSize)
  }
  
  public func italics() -> NSFont? {
    return withTraits(.italic)
  }
  
  public func bold() -> NSFont? {
    return withTraits(.bold)
  }
}
