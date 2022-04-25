import Foundation

/// Stores the colors to use for each biome, loaded from resource packs.
public struct BiomeColors {
  // MARK: Vanilla colors, overrides and filters
  
  public static let vanillaSpruceLeavesColor = RGBColor(r: 97, g: 153, b: 97)
  public static let vanillaBirchLeavesColor = RGBColor(r: 128, g: 167, b: 85)
  public static let vanillaLilyPadColor = RGBColor(r: 32, g: 128, b: 48)
  public static let vanillaBadlandsGrassColor = RGBColor(r: 144, g: 129, b: 77)
  public static let vanillaBadlandsFoliageColor = RGBColor(r: 158, g: 129, b: 77)
  public static let vanillaSwampColor = RGBColor(hexCode: 0x6a7039)
  
  /// The grass color used when something fails.
  public static let defaultGrassColor = RGBColor(r: 72, g: 181, b: 24)
  /// The foliage color used when something fails.
  public static let defaultFoliageColor = RGBColor(r: 72, g: 181, b: 24)
  
  /// Grass colors that vanilla hardcodes.
  public static let vanillaGrassColorOverrides: BiomeModifiers<RGBColor> = [
    .category(.swamp): Self.vanillaSwampColor,
    .category(.badlands): Self.vanillaBadlandsGrassColor
  ]
  
  /// Grass color filters that vanilla applies.
  public static let vanillaGrassColorFilters: BiomeModifiers<(RGBColor) -> RGBColor> = [
    .identifier(Identifier(name: "dark_forest")): { color in
      return RGBColor(hexCode: ((color.hexCode & 0xfefefe) + 0x28340a) >> 1)
    }
  ]
  
  /// Foliage colors that vanilla hardcodes.
  public static let vanillaFoliageColorOverrides: BiomeModifiers<RGBColor> = [
    .category(.swamp): Self.vanillaSwampColor,
    .category(.badlands): Self.vanillaBadlandsFoliageColor
  ]
  
  /// Foliage color filters that vanilla applies.
  public static let vanillaFoliageColorFilters: BiomeModifiers<(RGBColor) -> RGBColor> = [:]
  
  /// Block colors that vanilla hardcodes.
  public static let vanillaBlockColorOverrides: [Identifier: RGBColor] = [
    Identifier(name: "spruce_leaves"): Self.vanillaSpruceLeavesColor,
    Identifier(name: "birch_leaves"): Self.vanillaBirchLeavesColor
  ]
  
  // MARK: Color maps
  
  /// The color map containing biome foliage colors.
  public var foliageColorMap: BiomeColorMap
  /// The color map containing biome grass colors.
  public var grassColorMap: BiomeColorMap
  /// Colors to use for certain blocks instead of the colors from the biome color maps.
  public var blockColorOverrides: [Identifier: RGBColor] = [:]
  
  // MARK: Init
  
  /// Creates an empty biome colors resource.
  public init() {
    foliageColorMap = BiomeColorMap()
    grassColorMap = BiomeColorMap()
  }
  
  /// Creates a new biome colors resource from the colormaps in a resource pack directory.
  /// - Parameter colormapDirectory: The colormap directory of a resource pack. Must contain `foliage.png` and `grass.png`.
  /// - Parameter grassColorOverrides: Overrides for the grass colors of specific biomes. If `nil`, the vanilla ones are used.
  /// - Parameter grassColorFilters: Filters to apply to the grass colors of specific biomes after retrieving them from the resource pack's
  ///                                color map. If `nil`, the vanilla ones are used.
  /// - Parameter foliageColorOverrides: Overrides for the foliage colors of specific biomes. If `nil`, the vanilla ones are used.
  /// - Parameter foliageColorFilters: Filters to apply to the foliage colors of specific biomes after retrieving them from the resource pack's
  ///                                  color map. If `nil`, the vanilla ones are used.
  /// - Parameter blockColorOverrides: Overrides the colors of any blocks specified.
  /// - Parameter defaultFoliageColor: Color to use for foliage when something fails.
  /// - Parameter defaultGrassColor: Color to use for grass when something fails.
  public init(
    from colormapDirectory: URL,
    grassColorOverrides: BiomeModifiers<RGBColor>? = nil,
    grassColorFilters: BiomeModifiers<(RGBColor) -> RGBColor>? = nil,
    foliageColorOverrides: BiomeModifiers<RGBColor>? = nil,
    foliageColorFilters: BiomeModifiers<(RGBColor) -> RGBColor>? = nil,
    blockColorOverrides: [Identifier: RGBColor]? = nil,
    defaultFoliageColor: RGBColor? = nil,
    defaultGrassColor: RGBColor? = nil
  ) throws {
    let foliageMapFile = colormapDirectory.appendingPathComponent("foliage.png")
    let grassMapFile = colormapDirectory.appendingPathComponent("grass.png")
    
    do {
      foliageColorMap = try BiomeColorMap(
        from: foliageMapFile,
        biomes: RegistryStore.shared.biomeRegistry.biomes,
        fallbackColor: defaultFoliageColor ?? Self.defaultFoliageColor,
        overrides: foliageColorOverrides ?? Self.vanillaFoliageColorOverrides,
        filters: foliageColorFilters ?? Self.vanillaFoliageColorFilters)
    } catch {
      throw BiomeError.failedToLoadFoliageColorMap(error)
    }
    
    do {
      grassColorMap = try BiomeColorMap(
        from: grassMapFile,
        biomes: RegistryStore.shared.biomeRegistry.biomes,
        fallbackColor: defaultGrassColor ?? Self.defaultGrassColor,
        overrides: grassColorOverrides ?? Self.vanillaGrassColorOverrides,
        filters: grassColorFilters ?? Self.vanillaGrassColorFilters)
    } catch {
      throw BiomeError.failedToLoadGrassColorMap(error)
    }
    
    self.blockColorOverrides = blockColorOverrides ?? Self.vanillaBlockColorOverrides
  }
  
  // MARK: Access
  
  /// Get the tint color for a block.
  ///
  /// Respects ``blockColorOverrides``.
  ///
  /// - Parameters:
  ///   - block: The block.
  ///   - position: The position of the block. Currently ignored.
  ///   - biome: The biome the block is in.
  /// - Returns: A tint color. Returns `nil` if the block doesn't need a tint to be applied and in some cases where biome color look ups
  ///            fail which could happen if plugins mess with this.
  public func color(for block: Block, at position: BlockPosition, in biome: Biome) -> RGBColor? {
    if let tintColor = blockColorOverrides[block.identifier] {
      return tintColor
    }
    
    if let tint = block.tint {
      switch tint {
        case .computed(let computedTintType):
          switch computedTintType {
            case .waterTint:
              return biome.waterColor
            case .foliageTint:
              return foliageColorMap.color(for: biome)
            case .grassTint, .sugarCaneTint, .shearingDoublePlantTint:
              return grassColorMap.color(for: biome)
            case .lilyPadTint:
              return Self.vanillaLilyPadColor
          }
        case .hardcoded(let tintColor):
          return tintColor
      }
    } else {
      return nil
    }
  }
}
