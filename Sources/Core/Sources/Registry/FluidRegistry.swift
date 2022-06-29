import Foundation

/// An error to do with fluids.
public enum FluidError: LocalizedError {
  /// Failed to load fluid data from pixlyzer.
  case failedToLoadPixlyzerFluids(Error)
}

/// Holds information about fluids.
public struct FluidRegistry: Codable {
  /// All fluids. Indexed by fluid id.
  public var fluids: [Fluid] = []
  /// Maps biome identifier to an index in `fluids`.
  private var identifierToFluidId: [Identifier: Int] = [:]

  // MARK: Init

  /// Creates an empty fluid registry.
  public init() {}

  /// Creates a populated fluid registry.
  public init(fluids: [Fluid]) {
    self.fluids = fluids
    for fluid in fluids {
      identifierToFluidId[fluid.identifier] = fluid.id
    }
  }

  // MARK: Access

  /// Get information about the fluid specified.
  /// - Parameter identifier: Fluid identifier.
  /// - Returns: Fluid information. `nil` if fluid doesn't exist.
  public func fluid(for identifier: Identifier) -> Fluid? {
    if let index = identifierToFluidId[identifier] {
      return fluids[index]
    } else {
      return nil
    }
  }

  /// Get information about the fluid specified.
  /// - Parameter id: A fluid id.
  /// - Returns: Fluid information. `nil` if fluid id is out of range.
  ///
  /// Will fatally crash if the fluid id doesn't exist. Use wisely.
  public func fluid(withId id: Int) -> Fluid {
    // TODO: should this really fatally crash?
    return fluids[id]
  }
}
