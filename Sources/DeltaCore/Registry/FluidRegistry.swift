import Foundation

/// An error to do with fluids.
public enum FluidError: LocalizedError {
  /// Failed to load fluid data from pixlyzer.
  case failedToLoadPixlyzerFluids(Error)
}

/// Holds information about fluids.
public struct FluidRegistry {
  /// All fluids.
  public var fluids: [Fluid] = []
  /// Used to index `fluids`. Maps a fluid id to an index in `fluids`.
  private var fluidIdToIndex: [Int: Int] = [:]
  /// Maps biome identifier to an index in `fluids`.
  private var identifierToIndex: [Identifier: Int] = [:]
  
  // MARK: Init
  
  /// Creates an empty fluid registry.
  public init() {}
  
  /// Creates a populated fluid registry.
  public init(fluids: [Fluid]) {
    self.fluids = fluids
    for (index, fluid) in fluids.enumerated() {
      fluidIdToIndex[fluid.id] = index
      identifierToIndex[fluid.identifier] = index
    }
  }
  
  // MARK: Access
  
  /// Get information about the fluid specified.
  /// - Parameter identifier: Fluid identifier.
  /// - Returns: Fluid information. `nil` if fluid doesn't exist.
  public func fluid(for identifier: Identifier) -> Fluid? {
    if let index = identifierToIndex[identifier] {
      return fluids[index]
    } else {
      return nil
    }
  }
  
  /// Get information about the fluid specified.
  /// - Parameter id: A biome id.
  /// - Returns: Fluid information. `nil` if biome id is out of range.
  public func fluid(withId id: Int) -> Fluid? {
    if let index = fluidIdToIndex[id] {
      return fluids[index]
    } else {
      return nil
    }
  }
}

extension FluidRegistry: PixlyzerRegistry {
  public static func load(from pixlyzerFile: URL) throws -> FluidRegistry {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    do {
      let data = try Data(contentsOf: pixlyzerFile)
      let pixlyzerFluids = try decoder.decode([String: PixlyzerFluid].self, from: data)
      let fluids = try pixlyzerFluids.map { Fluid(from: $0.value, identifier: try Identifier($0.key)) }
      return FluidRegistry(fluids: fluids)
    } catch {
      throw FluidError.failedToLoadPixlyzerFluids(error)
    }
  }
  
  static func getDownloadURL(for version: String) -> URL {
    return URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(version)/fluids.min.json")!
  }
}
