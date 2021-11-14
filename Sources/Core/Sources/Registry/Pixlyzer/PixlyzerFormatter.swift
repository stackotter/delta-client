import Foundation

public enum PixlyzerError: LocalizedError {
  /// The block with the specified id is missing.
  case missingBlock(Int)
  /// An AABB's vertex is of invalid length.
  case invalidAABBVertex([Float])
  /// The entity registry does not contain the player entity.
  case entityRegistryMissingPlayer
}

public enum PixlyzerFormatter {
  /// Downloads the pixlyzer registries, reformats them, and caches them to an output directory.
  /// - Parameter version: The minecraft version string (e.g. '1.16.1').
  public static func downloadAndFormatRegistries(_ version: String) throws -> Registry {
    let fluidsDownloadURL = URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(version)/fluids.min.json")!
    let blocksDownloadURL = URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(version)/blocks.min.json")!
    let biomesDownloadURL = URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(version)/biomes.min.json")!
    let entitiesDownloadURL = URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(version)/entities.min.json")!
    let shapeRegistryDownloadURL = URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/master/version/\(version)/shapes.min.json")!
    
    // Load and decode pixlyzer data
    log.info("Downloading and decoding pixlyzer fluids")
    let pixlyzerFluids: [String: PixlyzerFluid] = try downloadJSON(fluidsDownloadURL, convertSnakeCase: true)
    log.info("Downloading and decoding pixlyzer biomes")
    let pixlyzerBiomes: [String: PixlyzerBiome] = try downloadJSON(biomesDownloadURL, convertSnakeCase: true)
    log.info("Downloading and decoding pixlyzer blocks")
    let pixlyzerBlocks: [String: PixlyzerBlock] = try downloadJSON(blocksDownloadURL, convertSnakeCase: false)
    log.info("Downloading and decoding pixlyzer entities")
    let pixlyzerEntities: [String: PixlyzerEntity] = try downloadJSON(entitiesDownloadURL, convertSnakeCase: true)
    log.info("Downloading and decoding pixlyzer shapes")
    let pixlyzerShapeRegistry: PixlyzerShapeRegistry = try downloadJSON(shapeRegistryDownloadURL, convertSnakeCase: false)
    
    // Process fluids
    log.info("Processing pixlyzer fluid registry")
    guard
      let waterStill = pixlyzerFluids["minecraft:water"],
      let lavaStill = pixlyzerFluids["minecraft:lava"]
    else {
      log.error("Failed to locate all required fluids")
      Foundation.exit(1)
    }
    
    let water = Fluid(
      id: 0,
      identifier: Identifier(name: "water"),
      flowingTexture: Identifier(name: "block/water_flow"),
      stillTexture: Identifier(name: "block/water_still"),
      dripParticleType: waterStill.dripParticleType)
    let lava = Fluid(
      id: 1,
      identifier: Identifier(name: "lava"),
      flowingTexture: Identifier(name: "block/lava_flow"),
      stillTexture: Identifier(name: "block/lava_still"),
      dripParticleType: lavaStill.dripParticleType)
    let fluids = [water, lava]
    
    var pixlyzerFluidIdToFluidId: [Int: Int] = [:]
    for (identifier, pixlyzerFluid) in pixlyzerFluids {
      if identifier.contains("water") {
        pixlyzerFluidIdToFluidId[pixlyzerFluid.id] = water.id
      } else if identifier.contains("lava") {
        pixlyzerFluidIdToFluidId[pixlyzerFluid.id] = lava.id
      }
    }
    
    // Process biomes
    log.info("Processing pixlyzer biome registry")
    var biomes: [Int: Biome] = [:]
    for (identifier, pixlyzerBiome) in pixlyzerBiomes {
      let identifier = try Identifier(identifier)
      let biome = Biome(from: pixlyzerBiome, identifier: identifier)
      biomes[biome.id] = biome
    }
    
    // Process entities
    log.info("Processing pixlyzer entity registry")
    var entities: [Int: EntityKind] = [:]
    for (identifier, pixlyzerEntity) in pixlyzerEntities {
      if let identifier = try? Identifier(identifier) {
        if let entity = EntityKind(pixlyzerEntity, identifier: identifier) {
          entities[entity.id] = entity
        }
      }
    }
    
    // Process shapes
    log.info("Processing pixlyzer shape registry")
    var aabbs: [AxisAlignedBoundingBox] = []
    for pixlyzerAABB in pixlyzerShapeRegistry.aabbs {
      aabbs.append(try AxisAlignedBoundingBox(from: pixlyzerAABB))
    }
    
    var shapes: [[AxisAlignedBoundingBox]] = []
    for shape in pixlyzerShapeRegistry.shapes {
      let ids = shape.items
      var boxes: [AxisAlignedBoundingBox] = []
      for id in ids {
        boxes.append(aabbs[id])
      }
      shapes.append(boxes)
    }
    
    // Process blocks
    log.info("Processing pixlyzer block registry")
    var blocks: [Int: Block] = [:]
    var blockModelRenderDescriptors: [Int: [[BlockModelRenderDescriptor]]] = [:]
    for (identifier, pixlyzerBlock) in pixlyzerBlocks {
      let identifier = try Identifier(identifier)
      let fluid: Fluid?
      if let flowingFluid = pixlyzerBlock.flowFluid {
        guard let fluidId = pixlyzerFluidIdToFluidId[flowingFluid] else {
          log.error("Failed to get fluid from pixlyzer flowing fluid id")
          Foundation.exit(1)
        }
        
        fluid = fluids[fluidId]
      } else {
        fluid = nil
      }
      
      for (stateId, pixlyzerState) in pixlyzerBlock.states {
        let isWaterlogged = pixlyzerState.properties?.waterlogged == true || BlockRegistry.waterloggedBlockClasses.contains(pixlyzerBlock.className)
        let fluid = isWaterlogged ? water : fluid
        let block = Block(pixlyzerBlock, pixlyzerState, shapes: shapes, stateId: stateId, fluid: fluid, isWaterlogged: isWaterlogged, identifier: identifier)
        let descriptors = pixlyzerState.blockModelVariantDescriptors.map {
          $0.map {
            BlockModelRenderDescriptor(from: $0)
          }
        }
        blocks[stateId] = block
        blockModelRenderDescriptors[stateId] = descriptors
      }
    }
    
    var blockArray: [Block] = []
    var renderDescriptors: [[[BlockModelRenderDescriptor]]] = []
    for i in 0..<blocks.count {
      guard let block = blocks[i] else {
        throw PixlyzerError.missingBlock(i)
      }
      
      blockArray.append(block)
      renderDescriptors.append(blockModelRenderDescriptors[i] ?? [])
    }
    
    let fluidRegistry = FluidRegistry(fluids: fluids)
    let biomeRegistry = BiomeRegistry(biomes: biomes)
    let blockRegistry = BlockRegistry(blocks: blockArray, renderDescriptors: renderDescriptors)
    let entityRegistry = try EntityRegistry(entities: entities)
    
    return Registry(
      blockRegistry: blockRegistry,
      biomeRegistry: biomeRegistry,
      fluidRegistry: fluidRegistry,
      entityRegistry: entityRegistry)
  }
  
  private static func downloadJSON<T: Decodable>(_ url: URL, convertSnakeCase: Bool) throws -> T {
    let contents = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    if convertSnakeCase {
      decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    return try decoder.decode(T.self, from: contents)
  }
}
