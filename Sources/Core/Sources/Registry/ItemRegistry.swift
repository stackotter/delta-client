import Foundation

public enum ItemRegistryError: LocalizedError {
  case missingItem(id: Int)
}

/// Holds information about items.
public struct ItemRegistry: Codable {
  public var items: [Item] = []
  private var identifierToId: [Identifier: Int] = [:]

  /// Creates an empty item registry.
  public init() {}

  /// Creates a populated item registry.
  /// - Parameter items: The items to put in the registry, keyed by id.
  /// - Throws: ``ItemRegistryError/missingItem(id:)`` if the item ids don't make up a continuous
  ///   block starting at 0.
  public init(items: [Int: Item]) throws {
    let maximumId = items.count - 1
    for id in 0..<maximumId {
      guard let item = items[id] else {
        throw ItemRegistryError.missingItem(id: id)
      }
      self.items.append(item)

      identifierToId[item.identifier] = id
    }
  }

  /// Gets the specified item.
  public func item(for identifier: Identifier) -> Item? {
    if let id = identifierToId[identifier] {
      return items[id]
    } else {
      return nil
    }
  }

  /// Gets the specified item.
  public func item(withId id: Int) -> Item? {
    guard id >= 0, id < items.count else {
      return nil
    }

    return items[id]
  }
}
