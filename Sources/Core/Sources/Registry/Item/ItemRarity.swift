import Foundation

/// The rarity of an item.
public enum ItemRarity: Int, Codable {
  case common = 0
  case uncommon = 1
  case rare = 2
  case epic = 3

  /// The color of text to use for this rarity.
  public var color: ChatComponent.Color {
    switch self {
      case .common:
        return .white
      case .uncommon:
        return .yellow
      case .rare:
        return .aqua
      case .epic:
        return .purple
    }
  }
}
