import Foundation
import simd

extension BlockModelPalette {
  public init(from cache: Data) throws {
    self.init()
    
    let cachedPalette = try ProtobufBlockModelPalette(serializedData: cache)
    for cachedVariants in cachedPalette.models {
      if cachedVariants.variants.isEmpty {
        continue
      }
      
      let variants: [BlockModel] = cachedVariants.variants.map { cachedBlockModel in
        BlockModel(from: cachedBlockModel)
      }
      
      models.append(variants)
    }
    
    displayTransforms = cachedPalette.displayTransforms.map {
      BlockModelDisplayTransforms(from: $0)
    }
  }
  
  public func serialize() throws -> Data {
    var cachedPalette = ProtobufBlockModelPalette()
    cachedPalette.models = models.map { variants in
      let cachedVariants: [ProtobufBlockModel] = variants.map { model in
        let cachedParts = model.parts.map { part in
          ProtobufBlockModelPart(from: part)
        }
        var cachedVariant = ProtobufBlockModel()
        cachedVariant.parts = cachedParts
        cachedVariant.cullingFaces = model.cullingFaces.map { ProtobufDirection(from: $0) }
        cachedVariant.cullableFaces = model.cullableFaces.map { ProtobufDirection(from: $0) }
        cachedVariant.nonCullableFaces = model.nonCullableFaces.map { ProtobufDirection(from: $0) }
        cachedVariant.textureType = ProtobufTextureType(rawValue: model.textureType.rawValue)!
        return cachedVariant
      }
      var cache = ProtobufVariants()
      cache.variants = cachedVariants
      return cache
    }
    
    cachedPalette.displayTransforms = displayTransforms.map {
      ProtobufDisplayTransforms(from: $0)
    }
    
    let data = try cachedPalette.serializedData()
    
    return data
  }
}

extension BlockModelDisplayTransforms {
  init(from cache: ProtobufDisplayTransforms) {
    self.init(
      thirdPersonRightHand: matrix_float4x4(from: cache.thirdPersonRightHand),
      thirdPersonLeftHand: matrix_float4x4(from: cache.thirdPersonLeftHand),
      firstPersonRightHand: matrix_float4x4(from: cache.firstPersonRightHand),
      firstPersonLeftHand: matrix_float4x4(from: cache.firstPersonLeftHand),
      gui: matrix_float4x4(from: cache.gui),
      head: matrix_float4x4(from: cache.head),
      ground: matrix_float4x4(from: cache.ground),
      fixed: matrix_float4x4(from: cache.fixed))
  }
}

extension ProtobufDisplayTransforms {
  init(from transforms: BlockModelDisplayTransforms) {
    self.init()
    thirdPersonRightHand = transforms.thirdPersonRightHand.data
    thirdPersonLeftHand = transforms.thirdPersonLeftHand.data
    firstPersonRightHand = transforms.firstPersonRightHand.data
    firstPersonLeftHand = transforms.firstPersonLeftHand.data
    gui = transforms.gui.data
    head = transforms.head.data
    ground = transforms.ground.data
    fixed = transforms.fixed.data
  }
}

extension BlockModel {
  init(from cache: ProtobufBlockModel) {
    let parts: [BlockModelPart] = cache.parts.map {
      BlockModelPart(from: $0)
    }
    
    let cullingFaces = Set(cache.cullingFaces.map { Direction(rawValue: $0.rawValue)! })
    let cullableFaces = Set(cache.cullableFaces.map { Direction(rawValue: $0.rawValue)! })
    let nonCullableFaces = Set(cache.nonCullableFaces.map { Direction(rawValue: $0.rawValue)! })
    let textureType = TextureType(rawValue: cache.textureType.rawValue)!
    
    self.init(
      parts: parts,
      cullingFaces: cullingFaces,
      cullableFaces: cullableFaces,
      nonCullableFaces: nonCullableFaces,
      textureType: textureType)
  }
}

extension BlockModelPart {
  init(from cache: ProtobufBlockModelPart) {
    let elements: [BlockModelElement] = cache.elements.map {
      BlockModelElement(from: $0)
    }
    
    self.init(
      ambientOcclusion: cache.ambientOcclusion,
      displayTransformsIndex: cache.hasDisplayTransformsIndex ? Int(cache.displayTransformsIndex) : nil,
      elements: elements)
  }
}

extension BlockModelElement {
  init(from cache: ProtobufBlockModelElement) {
    let faces: [BlockModelFace] = cache.faces.map {
      BlockModelFace(from: $0)
    }
    
    let transformation = matrix_float4x4(from: cache.transformation)
    self.init(
      transformation: transformation,
      shade: cache.shade,
      faces: faces)
  }
}

extension BlockModelFace {
  init(from cache: ProtobufBlockModelFace) {
    let uvs = [
      SIMD2<Float>(cache.uvs[0], cache.uvs[1]),
      SIMD2<Float>(cache.uvs[2], cache.uvs[3]),
      SIMD2<Float>(cache.uvs[4], cache.uvs[5]),
      SIMD2<Float>(cache.uvs[6], cache.uvs[7])]
    
    self.init(
      direction: Direction(from: cache.direction)!,
      actualDirection: Direction(from: cache.actualDirection)!,
      uvs: uvs,
      texture: Int(cache.texture),
      cullface: cache.hasCullface ? Direction(from: cache.cullface) : nil,
      isTinted: cache.isTinted)
  }
}

fileprivate extension Direction {
  init?(from cache: ProtobufDirection) {
    self.init(rawValue: cache.rawValue)
  }
}

extension matrix_float4x4 {
  var data: Data {
    var mutableSelf = self
    let data = Data(bytes: &mutableSelf, count: MemoryLayout<matrix_float4x4>.size)
    return data
  }
  
  init(from data: Data) {
    self.init()
    _ = withUnsafeMutableBytes(of: &self.columns) {
      data.copyBytes(to: $0)
    }
  }
}

extension ProtobufDirection {
  init(from direction: Direction) {
    self.init(rawValue: direction.rawValue)!
  }
}

extension ProtobufBlockModelPart {
  init(from model: BlockModelPart) {
    self.init()
    ambientOcclusion = model.ambientOcclusion
    clearDisplayTransformsIndex()
    if let index = model.displayTransformsIndex {
      displayTransformsIndex = Int32(index)
    }
    elements = model.elements.map {
      ProtobufBlockModelElement(from: $0)
    }
  }
}

extension ProtobufBlockModelElement {
  init(from element: BlockModelElement) {
    self.init()
    transformation = element.transformation.data
    shade = element.shade
    faces = element.faces.map {
      ProtobufBlockModelFace(from: $0)
    }
  }
}

extension ProtobufBlockModelFace {
  init(from face: BlockModelFace) {
    self.init()
    direction = ProtobufDirection(from: face.direction)
    actualDirection = ProtobufDirection(from: face.actualDirection)
    uvs = [
      face.uvs[0].x,
      face.uvs[0].y,
      face.uvs[1].x,
      face.uvs[1].y,
      face.uvs[2].x,
      face.uvs[2].y,
      face.uvs[3].x,
      face.uvs[3].y]
    texture = Int32(face.texture)
    clearCullface()
    if let cullface = face.cullface {
      self.cullface = ProtobufDirection(from: cullface)
    }
    isTinted = face.isTinted
  }
}
