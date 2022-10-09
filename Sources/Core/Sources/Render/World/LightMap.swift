import Foundation
import Metal
import simd

struct LightMap {
  static let gamma: Double = 0

  var pixels: [SIMD3<UInt8>]
  var blockFlicker: Double = 1
  var ambientLight: Double
  var baseLevels: [Double]
  var lastFlickerUpdateTick: Int?

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

  mutating func update(time: Int, tick: Int, ambientLight: Double) {
    if ambientLight != self.ambientLight {
      baseLevels = Self.generateBaseLevels(ambientLight)
      self.ambientLight = ambientLight
    }

    // TODO: When lightning is occurring, hardcode brightness to 1
    // TODO: implement night vision and water effects
    let sunBrightness = Self.getSunBrightness(at: time)
    let skyBrightness = sunBrightness * 0.95 + 0.05

    let r = MathUtil.lerp(from: skyBrightness, to: 1, progress: 0.35)
    let g = MathUtil.lerp(from: skyBrightness, to: 1, progress: 0.35)
    let b = 1.0
    let skyColor = SIMD3<Double>(r, g, b)

    updateBlockFlicker(tick)
    let blockBrightness = blockFlicker + 1.5

    for skyLightLevel in 0..<LightLevel.levelCount {
      for blockLightLevel in 0..<LightLevel.levelCount {
        let sky = baseLevels[skyLightLevel] * skyBrightness
        let block = baseLevels[blockLightLevel] * blockBrightness
        let blockColor = SIMD3<Double>(
          block,
          block * ((block * 0.6 + 0.4) * 0.6 + 0.4),
          block * (block * block * 0.6 + 0.4)
        )

        // TODO: implement branch for dimensions with no sky lighting (apparently The End)
        var pixel = blockColor

        pixel += skyColor * sky
        pixel = MathUtil.lerp(from: pixel, to: SIMD3<Double>(repeating: 0.75), progress: 0.04)
        pixel = clamp(pixel, min: 0.0, max: 1.0)

        var copy = pixel
        copy.x = Self.inverseGamma(pixel.x)
        copy.y = Self.inverseGamma(pixel.y)
        copy.z = Self.inverseGamma(pixel.z)

        pixel = MathUtil.lerp(from: pixel, to: copy, progress: Self.gamma)
        pixel = MathUtil.lerp(from: pixel, to: SIMD3<Double>(repeating: 0.75), progress: 0.04)
        pixel = clamp(pixel, min: 0.0, max: 1.0)
        pixel *= 255

        let index = Self.index(skyLightLevel, blockLightLevel)
        pixels[index] = SIMD3<UInt8>(pixel)
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
    lastFlickerUpdateTick = tick

    var rng = Random()
    for _ in 0..<updateCount {
      blockFlicker += (rng.nextDouble() - rng.nextDouble()) * rng.nextDouble() * rng.nextDouble() * 0.1
      blockFlicker *= 0.9
    }
  }

  mutating func getBuffer(_ device: MTLDevice) throws -> MTLBuffer {
    return try MetalUtil.makeBuffer(
      device,
      bytes: &pixels,
      length: LightLevel.levelCount * LightLevel.levelCount * MemoryLayout<SIMD3<UInt8>>.stride,
      options: .storageModeShared,
      label: "lightMap"
    )
  }

  mutating func getTexture(_ device: MTLDevice) -> MTLTexture? {
    var bgraPixels: [SIMD4<UInt8>] = []
    for pixel in pixels {
      bgraPixels.append([pixel.z, pixel.y, pixel.x, 255])
    }

    let descriptor = MTLTextureDescriptor()
    descriptor.width = 16
    descriptor.height = 16
    descriptor.pixelFormat = .bgra8Unorm
    let texture = device.makeTexture(descriptor: descriptor)
    texture?.replace(region: MTLRegionMake2D(0, 0, 16, 16), mipmapLevel: 0, withBytes: &bgraPixels, bytesPerRow: 16 * 4)
    texture?.label = "lightMapTexture"
    return texture
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
      level = level / (4 - 3 * level)
      levels.append(MathUtil.lerp(from: level, to: 1, progress: ambientLight))
    }

    return levels
  }

  static func getSunBrightness(at time: Int) -> Double {
    // TODO: Implement the effect of rain and thunder of sun brightness
    let angle = getSunAngle(at: time)
    var brightness = 1 - (cos(angle * .pi * 2) * 2 + 0.2)
    brightness = MathUtil.clamp(brightness, 0, 1)
    brightness = 1 - brightness
    return brightness * 0.8 + 0.2
  }

  static func getSunAngle(at time: Int) -> Double {
    // I actually don't really know what this maths is doing, it's apparently how vanilla calculates it
    // though. It's probably just calculating the angle but adjusting the center of the orbit to be below
    // the ground so that the length of day is more realistic or something.
    let fraction = Double(time) / 24000 - 0.25
    let fractionalPart = fraction - floor(fraction)
    let angle = 0.5 - cos(fractionalPart * .pi) / 2
    let adjusted = (fractionalPart * 2 + angle) / 3
    return adjusted
  }
}
