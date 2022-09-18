import Foundation
import ZippyJSON

public enum PixlyzerError: LocalizedError {
  /// The block with the specified id is missing.
  case missingBlock(Int)
  /// An AABB's vertex is of invalid length.
  case invalidAABBVertex([Double])
  /// The entity registry does not contain the player entity.
  case entityRegistryMissingPlayer
  /// The string could not be converted to data using UTF8.
  case invalidUTF8BlockName(String)
  /// Either lava or water is missing from the pixlyzer fluid registry.
  case missingExpectedFluids
  /// Failed to get the water fluid from the fluid registry.
  case failedToGetWaterFluid
}

/// A utility for downloading and reformatting data from the Pixlyzer data repository.
public enum PixlyzerFormatter {
  /// Downloads the pixlyzer registries, reformats them, and caches them to an output directory.
  /// - Parameter version: The minecraft version string (e.g. '1.16.1').
  public static func downloadAndFormatRegistries(_ version: String) throws -> RegistryStore {
    let pixlyzerCommit = "7cceb5481e6f035d274204494030a76f47af9bb5"
    let pixlyzerItemCommit = "c623c21be12aa1f9be3f36f0e32fbc61f8f16bd1"
    let baseURL = "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/\(pixlyzerCommit)/version/\(version)"

    // swiftlint:disable force_unwrapping
    let fluidsDownloadURL = URL(string: "\(baseURL)/fluids.min.json")!
    let blocksDownloadURL = URL(string: "\(baseURL)/blocks.min.json")!
    let biomesDownloadURL = URL(string: "\(baseURL)/biomes.min.json")!
    let entitiesDownloadURL = URL(string: "\(baseURL)/entities.min.json")!
    let shapeRegistryDownloadURL = URL(string: "\(baseURL)/shapes.min.json")!
    let itemsDownloadURL = URL(string: "https://gitlab.bixilon.de/bixilon/pixlyzer-data/-/raw/\(pixlyzerItemCommit)/version/\(version)/items.min.json")!
    // swiftlint:enable force_unwrapping

    // Load and decode pixlyzer data
    log.info("Downloading and decoding pixlyzer items")
    let pixlyzerItems: [String: PixlyzerItem] = try downloadJSON(itemsDownloadURL, convertSnakeCase: false)
    log.info("Downloading and decoding pixlyzer fluids")
    let pixlyzerFluids: [String: PixlyzerFluid] = try downloadJSON(fluidsDownloadURL, convertSnakeCase: true)
    log.info("Downloading and decoding pixlyzer biomes")
    let pixlyzerBiomes: [String: PixlyzerBiome] = try downloadJSON(biomesDownloadURL, convertSnakeCase: true)
    log.info("Downloading and decoding pixlyzer blocks")
    let pixlyzerBlocks: [String: PixlyzerBlock] = try downloadJSON(blocksDownloadURL, convertSnakeCase: false, useZippyJSON: false)
    log.info("Downloading and decoding pixlyzer entities")
    let pixlyzerEntities: [String: PixlyzerEntity] = try downloadJSON(entitiesDownloadURL, convertSnakeCase: true)
    log.info("Downloading and decoding pixlyzer shapes")
    let pixlyzerShapeRegistry: PixlyzerShapeRegistry = try downloadJSON(shapeRegistryDownloadURL, convertSnakeCase: false)

    // Process fluids
    log.info("Processing pixlyzer fluid registry")
    let (fluidRegistry, pixlyzerFluidIdToFluidId) = try Self.createFluidRegistry(from: pixlyzerFluids)

    // Process biomes
    log.info("Processing pixlyzer biome registry")
    let biomeRegistry = try Self.createBiomeRegistry(from: pixlyzerBiomes)

    // Process entities
    log.info("Processing pixlyzer entity registry")
    let entityRegistry = try Self.createEntityRegistry(from: pixlyzerEntities)

    // Process blocks
    log.info("Processing pixlyzer block registry")
    let blockRegistry = try Self.createBlockRegistry(
      from: pixlyzerBlocks,
      shapes: pixlyzerShapeRegistry,
      pixlyzerFluidIdToFluidId: pixlyzerFluidIdToFluidId,
      fluidRegistry: fluidRegistry
    )

    // Process items
    log.info("Processing pixlyzer item registry")
    let itemRegistry = try Self.createItemRegistry(from: pixlyzerItems)

    return RegistryStore(
      blockRegistry: blockRegistry,
      biomeRegistry: biomeRegistry,
      fluidRegistry: fluidRegistry,
      entityRegistry: entityRegistry,
      itemRegistry: itemRegistry
    )
  }

  private static func createFluidRegistry(
    from pixlyzerFluids: [String: PixlyzerFluid]
  ) throws -> (fluidRegistry: FluidRegistry, pixlyzerFluidIdToFluidId: [Int: Int]) {
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
      dripParticleType: waterStill.dripParticleType
    )
    let lava = Fluid(
      id: 1,
      identifier: Identifier(name: "lava"),
      flowingTexture: Identifier(name: "block/lava_flow"),
      stillTexture: Identifier(name: "block/lava_still"),
      dripParticleType: lavaStill.dripParticleType
    )
    let fluids = [water, lava]

    var pixlyzerFluidIdToFluidId: [Int: Int] = [:]
    for (identifier, pixlyzerFluid) in pixlyzerFluids {
      if identifier.contains("water") {
        pixlyzerFluidIdToFluidId[pixlyzerFluid.id] = water.id
      } else if identifier.contains("lava") {
        pixlyzerFluidIdToFluidId[pixlyzerFluid.id] = lava.id
      }
    }

    return (fluidRegistry: FluidRegistry(fluids: fluids), pixlyzerFluidIdToFluidId: pixlyzerFluidIdToFluidId)
  }

  private static func createBiomeRegistry(from pixlyzerBiomes: [String: PixlyzerBiome]) throws -> BiomeRegistry {
    var biomes: [Int: Biome] = [:]
    for (identifier, pixlyzerBiome) in pixlyzerBiomes {
      let identifier = try Identifier(identifier)
      let biome = Biome(from: pixlyzerBiome, identifier: identifier)
      biomes[biome.id] = biome
    }

    return BiomeRegistry(biomes: biomes)
  }

  private static func createEntityRegistry(from pixlyzerEntities: [String: PixlyzerEntity]) throws -> EntityRegistry {
    var entities: [Int: EntityKind] = [:]
    for (identifier, pixlyzerEntity) in pixlyzerEntities {
      if let identifier = try? Identifier(identifier) {
        if let entity = EntityKind(pixlyzerEntity, identifier: identifier) {
          entities[entity.id] = entity
        }
      }
    }

    return try EntityRegistry(entities: entities)
  }

  private static func createBlockRegistry(
    from pixlyzerBlocks: [String: PixlyzerBlock],
    shapes pixlyzerShapeRegistry: PixlyzerShapeRegistry,
    pixlyzerFluidIdToFluidId: [Int: Int],
    fluidRegistry: FluidRegistry
  ) throws -> BlockRegistry {
    // Process block shapes
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

    guard let water = fluidRegistry.fluid(for: Identifier(name: "water")) else {
      throw PixlyzerError.failedToGetWaterFluid
    }

    // Process blocks
    var blocks: [Int: Block] = [:]
    var blockModelRenderDescriptors: [Int: [[BlockModelRenderDescriptor]]] = [:]
    for (identifier, pixlyzerBlock) in pixlyzerBlocks {
      var identifier = try Identifier(identifier)
      identifier.name = "block/\(identifier.name)"
      let fluid: Fluid?
      if let flowingFluid = pixlyzerBlock.flowFluid {
        guard let fluidId = pixlyzerFluidIdToFluidId[flowingFluid] else {
          log.error("Failed to get fluid from pixlyzer flowing fluid id")
          Foundation.exit(1)
        }

        fluid = fluidRegistry.fluid(withId: fluidId)
      } else {
        fluid = nil
      }

      for (stateId, pixlyzerState) in pixlyzerBlock.states {
        let isWaterlogged = pixlyzerState.properties?.waterlogged == true || BlockRegistry.waterloggedBlockClasses.contains(pixlyzerBlock.className)
        let fluid = isWaterlogged ? water : fluid
        let block = Block(
          pixlyzerBlock,
          pixlyzerState,
          shapes: shapes,
          stateId: stateId,
          fluid: fluid,
          isWaterlogged: isWaterlogged,
          identifier: identifier
        )

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

    return BlockRegistry(blocks: blockArray, renderDescriptors: renderDescriptors)
  }

  private static func createItemRegistry(from pixlyzerItems: [String: PixlyzerItem]) throws -> ItemRegistry {
    var items: [Int: Item] = [:]
    for (identifierString, pixlyzerItem) in pixlyzerItems {
      var identifier = try Identifier(identifierString)
      identifier.name = "item/\(identifier.name)"
      let item = Item(from: pixlyzerItem, identifier: identifier)
      items[item.id] = item
    }

    return try ItemRegistry(items: items)
  }

  private static func downloadJSON<T: Decodable>(
    _ url: URL,
    convertSnakeCase: Bool,
    useZippyJSON: Bool = true
  ) throws -> T {
    let contents = try Data(contentsOf: url)

    if useZippyJSON {
      let decoder = CustomJSONDecoder()
      if convertSnakeCase {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
      }
      return try decoder.decode(T.self, from: contents)
    } else {
      let decoder = JSONDecoder()
      if convertSnakeCase {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
      }
      return try decoder.decode(T.self, from: contents)
    }
  }
}
