import Foundation

// TODO: Update this when adding a new protocol version (the format changes each version).
public struct EntityMetadataPacket: ClientboundPacket {
  public static let id: Int = 0x44

  public var entityId: Int

  public var metadata: [MetadataEntry]

  public struct MetadataEntry {
    public var index: Int
    public var value: Value
  }

  public enum Value {
    case byte(Int8)
    case varInt(Int)
    case float(Float)
    case string(String)
    case chat(ChatComponent)
    case optionalChat(ChatComponent?)
    case slot(Slot)
    case bool(Bool)
    case rotation(Vec3f)
    case position(BlockPosition)
    case optionalPosition(BlockPosition?)
    case direction(Direction)
    case optionalUUID(UUID?)
    case optionalBlockStateId(Int?)
    case nbt(NBT.Compound)
    case particle(Particle)
    case villagerData(type: Int, profession: Int, level: Int)
    case entityId(Int?)
    case pose(Pose)

    public enum Pose: Int {
      case standing = 0
      case fallFlying = 1
      case sleeping = 2
      case swimming = 3
      case spinAttack = 4
      case sneaking = 5
      case longJumping = 6
      case dying = 7
      case croaking = 8
      case usingTongue = 9
      case sitting = 10
      case roaring = 11
      case sniffing = 12
      case emerging = 13
      case digging = 14
    }

    public struct Particle {
      // TODO: These will need updating when adding support for new protocol versions. Ideally
      //   they should be loaded dynamically from either pixlyzer (I don't think it has the right
      //   data), or from our own data files of some sort.
      public static let blockParticleId = 3
      public static let dustParticleId = 14
      public static let fallingDustParticleId = 23
      public static let itemParticleId = 32

      public var id: Int
      public var data: Data?

      public enum Data {
        case block(blockStateId: Int)
        case dust(red: Float, green: Float, blue: Float, scale: Float)
        case fallingDust(blockStateId: Int)
        case item(Slot)
      }
    }
  }

  public init(from packetReader: inout PacketReader) throws {
    entityId = try packetReader.readVarInt()

    metadata = []
    while true {
      let index = try packetReader.readUnsignedByte()
      if index == 0xff {
        break
      }

      let type = try packetReader.readVarInt()
      let value: Value
      switch type {
        case 0:
          value = .byte(try packetReader.readByte())
        case 1:
          value = .varInt(try packetReader.readVarInt())
        case 2:
          value = .float(try packetReader.readFloat())
        case 3:
          value = .string(try packetReader.readString())
        case 4:
          value = .chat(try packetReader.readChat())
        case 5:
          value = .optionalChat(
            try packetReader.readOptional { reader in
              try reader.readChat()
            }
          )
        case 6:
          value = .slot(try packetReader.readSlot())
        case 7:
          value = .bool(try packetReader.readBool())
        case 8:
          value = .rotation(
            Vec3f(
              try packetReader.readFloat(),
              try packetReader.readFloat(),
              try packetReader.readFloat()
            )
          )
        case 9:
          value = .position(try packetReader.readBlockPosition())
        case 10:
          value = .optionalPosition(
            try packetReader.readOptional { reader in
              try reader.readBlockPosition()
            }
          )
        case 11:
          value = .direction(try packetReader.readDirection())
        case 12:
          value = .optionalUUID(
            try packetReader.readOptional { reader in
              try reader.readUUID()
            }
          )
        case 13:
          let rawValue = try packetReader.readVarInt()
          if rawValue == 0 {
            value = .optionalBlockStateId(nil)
          } else {
            value = .optionalBlockStateId(rawValue - 1)
          }
        case 14:
          value = .nbt(try packetReader.readNBTCompound())
        case 15:
          let particleId = try packetReader.readVarInt()
          let data: Value.Particle.Data?
          switch particleId {
            case Value.Particle.blockParticleId:
              data = .block(blockStateId: try packetReader.readVarInt())
            case Value.Particle.dustParticleId:
              data = .dust(
                red: try packetReader.readFloat(),
                green: try packetReader.readFloat(),
                blue: try packetReader.readFloat(),
                scale: try packetReader.readFloat()
              )
            case Value.Particle.fallingDustParticleId:
              data = .fallingDust(blockStateId: try packetReader.readVarInt())
            case Value.Particle.itemParticleId:
              data = .item(try packetReader.readSlot())
            default:
              data = nil
          }
          value = .particle(Value.Particle(id: particleId, data: data))
        case 16:
          value = .villagerData(
            type: try packetReader.readVarInt(),
            profession: try packetReader.readVarInt(),
            level: try packetReader.readVarInt()
          )
        case 17:
          // Value is an optional varint, but 0 represents `nil` and any other value
          // represents `1 + value`
          let rawValue = try packetReader.readVarInt()
          if rawValue == 0 {
            value = .entityId(nil)
          } else {
            value = .entityId(rawValue - 1)
          }
        case 18:
          let rawValue = try packetReader.readVarInt()
          guard let pose = Value.Pose(rawValue: rawValue) else {
            throw ClientboundPacketError.invalidPoseId(rawValue)
          }
          value = .pose(pose)
        default:
          throw ClientboundPacketError.invalidEntityMetadataDatatypeId(type)
      }

      metadata.append(MetadataEntry(index: Int(index), value: value))
    }
  }

  public func handle(for client: Client) throws {
    try client.game.accessEntity(id: entityId) { entity in
      guard
        let metadataComponent = entity.get(component: EntityMetadata.self),
        let kindId = entity.get(component: EntityKindId.self)
      else {
        log.warning("Entity '\(entityId)' is missing components required to handle \(Self.self)")
        return
      }

      guard let kind = kindId.entityKind else {
        log.warning("Invalid entity kind id '\(kindId.id)'")
        return
      }

      for entry in metadata {
        if kind.inheritanceChain.contains("MobEntity"), entry.index == 14 {
          guard case let .byte(flags) = entry.value else {
            throw ClientboundPacketError.incorrectEntityMetadataDatatype(
              property: "Mob.noAI",
              expectedType: "byte",
              value: entry.value
            )
          }

          metadataComponent.noAI = flags & 0x01 == 0x01
        }
      }
    }
  }
}
