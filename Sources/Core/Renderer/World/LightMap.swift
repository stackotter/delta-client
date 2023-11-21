import Foundation
import Metal
import FirebladeMath
// TODO: Move Vec3 and extensions of FirebladeMath into FirebladeMath to avoid this unnecessary import
import DeltaCore

// TODO: Make LightMap an ECS singleton
struct LightMap {
  static let gamma: Double = 0

  var pixels: [Vec3<UInt8>]
  var blockFlicker: Double = 1
  var ambientLight: Double
  var baseLevels: [Double]
  var lastFlickerUpdateTick: Int?
  var hasChanged = true

  init(ambientLight: Double) {
    baseLevels = Self.generateBaseLevels(ambientLight)
    self.ambientLight = ambientLight

    pixels = []
    for _ in 0..<LightLevel.levelCount {
      for _ in 0...LightLevel.levelCount {
        pixels.append(.zero)
      }
    }
  }

  // TODO: Refactor this function to be more delta clienty and look less like spaghetti Java code
  mutating func update(
    tick: Int,
    sunAngleRadians: Float,
    ambientLight: Double,
    dimensionHasSkyLight: Bool
  ) {
    guard tick != lastFlickerUpdateTick || ambientLight != self.ambientLight else {
      return
    }

    hasChanged = true

    // Update base levels if ambient light has changed
    if ambientLight != self.ambientLight {
      baseLevels = Self.generateBaseLevels(ambientLight)
      self.ambientLight = ambientLight
    }

    // Update block brightness
    updateBlockFlicker(tick)
    let blockBrightness = blockFlicker + 1.5

    // Update sky brightness
    // TODO: When lightning is occurring, hardcode brightness to 1
    // TODO: implement night vision and water effects
    let sunBrightness = Self.getSunBrightness(sunAngleRadians: sunAngleRadians)
    let skyBrightness = sunBrightness * 0.95 + 0.05

    let r = MathUtil.lerp(from: skyBrightness, to: 1, progress: 0.35)
    let g = MathUtil.lerp(from: skyBrightness, to: 1, progress: 0.35)
    let b = 1.0
    let skyColor = Vec3d(r, g, b)

    // Update light map
    for skyLightLevel in 0..<LightLevel.levelCount {
      for blockLightLevel in 0..<LightLevel.levelCount {
        let sky = baseLevels[skyLightLevel] * skyBrightness
        let block = baseLevels[blockLightLevel] * blockBrightness
        let blockColor = Vec3d(
          block,
          block * ((block * 0.6 + 0.4) * 0.6 + 0.4),
          block * (block * block * 0.6 + 0.4)
        )

        var pixel = blockColor

        if dimensionHasSkyLight {
          pixel += skyColor * sky
          pixel = MathUtil.lerp(from: pixel, to: Vec3d(repeating: 0.75), progress: 0.04)
        } else {
          pixel = MathUtil.lerp(from: pixel, to: [0.99, 1.12, 1.0], progress: 0.25)
        }

        pixel = MathUtil.clamp(pixel, min: 0.0, max: 1.0)

        var copy = pixel
        copy.x = Self.inverseGamma(pixel.x)
        copy.y = Self.inverseGamma(pixel.y)
        copy.z = Self.inverseGamma(pixel.z)

        pixel = MathUtil.lerp(from: pixel, to: copy, progress: Self.gamma)
        pixel = MathUtil.lerp(from: pixel, to: Vec3d(repeating: 0.75), progress: 0.04)
        pixel = MathUtil.clamp(pixel, min: 0.0, max: 1.0)
        pixel *= 255

        let index = Self.index(skyLightLevel, blockLightLevel)
        pixels[index] = Vec3<UInt8>(pixel)
      }
    }
  }

  mutating func updateBlockFlicker(_ tick: Int) {
    let updateCount: Int
    if let lastFlickerUpdateTick = lastFlickerUpdateTick {
      updateCount = tick - lastFlickerUpdateTick
    } else {
      updateCount = 1
    }

    guard updateCount != 0 else {
      return
    }

    var rng = Random()
    for _ in 0..<updateCount {
      blockFlicker += (rng.nextDouble() - rng.nextDouble()) * rng.nextDouble() * rng.nextDouble() * 0.1
      blockFlicker *= 0.9
    }

    lastFlickerUpdateTick = tick
  }

  mutating func getBuffer(_ device: MTLDevice, reusing previousBuffer: MTLBuffer? = nil) throws -> MTLBuffer {
    defer {
      hasChanged = false
    }

    let byteCount = LightLevel.levelCount * LightLevel.levelCount * MemoryLayout<Vec3<UInt8>>.stride
    if let previousBuffer = previousBuffer {
      if hasChanged {
        previousBuffer.contents().copyMemory(from: &pixels, byteCount: byteCount)
      }
      return previousBuffer
    } else {
      return try MetalUtil.makeBuffer(
        device,
        bytes: &pixels,
        length: byteCount,
        options: .storageModeShared,
        label: "lightMap"
      )
    }
  }

  static func index(_ skyLightLevel: Int, _ blockLightLevel: Int) -> Int {
    return skyLightLevel * LightLevel.levelCount + blockLightLevel
  }

  static func inverseGamma(_ value: Double) -> Double {
    let value = 1 - value
    return 1 - value * value * value * value
  }

  static func generateBaseLevels(_ ambientLight: Double) -> [Double] {
    var levels: [Double] = []

    for i in 0..<LightLevel.levelCount {
      var level = Double(i) / Double(LightLevel.maximumLightLevel)
      level /= (4 - 3 * level)
      levels.append(MathUtil.lerp(from: level, to: 1, progress: ambientLight))
    }

    return levels
  }

  static func getSunBrightness(sunAngleRadians: Float) -> Double {
    // TODO: Implement the effect of rain and thunder on sun brightness
    var brightness = Double(Foundation.cos(sunAngleRadians) * 2 + 0.2)
    brightness = MathUtil.clamp(brightness, 0, 1)
    return brightness * 0.8 + 0.2
  }
}
