import Foundation

/// A biome's grass or foliage color map.
public struct BiomeColorMap {
  /// Hardcoded override colors for biomes matching certain criteria.
  public var overrides: BiomeModifiers<RGBColor> = [:]
  /// Filters to apply colors of biomes matching certain criteria.
  public var filters: BiomeModifiers<(RGBColor) -> RGBColor> = [:]

  /// The underlying color map.
  private var colorMap = ColorMap()
  /// Precalculated colors for each biome indexed by biome id.
  private var colors: [Int: RGBColor] = [:]

  // MARK: Init

  /// Creates an empty biome color map.
  public init() {}

  /// Creates a new biome color map and precalculates the colors.
  /// - Parameters:
  ///   - colorMapPNG: The PNG color map containing to get biome colors from.
  ///   - biomes: Biomes to precalculate colors for.
  ///   - fallbackColor: The color to use when color calculation fails.
  ///   - overrides: A list of color overrides for biomes matching certain criteria.
  ///   - filters: Color filters to apply to biomes matching certain criteria. Color filters are applied to the calculated color before saving it to `colors`.
  init(
    from colorMapPNG: URL,
    biomes: [Int: Biome],
    fallbackColor: RGBColor,
    overrides: BiomeModifiers<RGBColor> = [:],
    filters: BiomeModifiers<(RGBColor) -> RGBColor> = [:]
  ) throws {
    colorMap = try ColorMap(from: colorMapPNG)

    guard colorMap.width == 256 && colorMap.height == 256 else {
      throw BiomeError.colorMapNot256By256Pixels
    }

    self.overrides = overrides
    self.filters = filters

    precalculate(biomes, fallback: fallbackColor)
  }

  // MARK: Access

  /// Get the precalculated color value for a biome.
  /// - Parameter biome: Biome to get color for.
  /// - Returns: The biome's color. If the look up fails, `nil` is returned.
  public func color(for biome: Biome) -> RGBColor? {
    if let color = colors[biome.id] {
      return color
    } else {
      log.warning("Biome color map look up failed, returning nil; biome.id=\(biome.id)")
      return nil
    }
  }

  // MARK: Color calculation

  /// Precalculates all of the biome's colors. Applies `overrides` and `filters`.
  /// - Parameters:
  ///   - biomes: Biomes to precalculate colors for.
  ///   - fallback: The color to use when color map look ups fail.
  public mutating func precalculate(_ biomes: [Int: Biome], fallback: RGBColor) {
    for (_, biome) in biomes {
      let overrideColor = overrides[biome]

      var color = overrideColor ?? calculateColor(biome, fallback: fallback)

      if let filter = filters[biome] {
        color = filter(color)
      }

      colors[biome.id] = color
    }
  }

  /// Calculate the color for a biome from the color map. To get the actual biome color (after overrides and filters), use ``color(for:)``.
  ///
  /// `overrides` and `filters` do not affect the color returned. The color is just retrieved using
  /// the biome's climate information (specifically temperature and rainfall) and the color map.
  ///
  /// - Parameters:
  ///   - biome: A biome.
  ///   - fallback: A color to use if the color lookup somehow ends up out of bounds.
  /// - Returns: The color for a biome.
  public func calculateColor(_ biome: Biome, fallback: RGBColor) -> RGBColor {
    let adjustedTemperature = MathUtil.clamp(biome.temperature, 0, 1)
    let adjustedRainfall = MathUtil.clamp(biome.rainfall, 0, 1) * adjustedTemperature

    let x = Int((1 - adjustedTemperature) * Float(colorMap.width - 1))
    let y = Int((1 - adjustedRainfall) * Float(colorMap.height - 1))
    let color = colorMap.color(atX: x, y: y) ?? fallback

    return color
  }
}
