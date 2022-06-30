import Foundation

public struct AdvancementsPacket: ClientboundPacket {
  public static let id: Int = 0x57

  public var shouldReset: Bool
  public var advancements: [Identifier: Advancement]
  public var advancementsToRemove: [Identifier]
  public var advancementProgresses: [Identifier: AdvancementProgress]

  public struct Advancement {
    public var hasParent: Bool
    public var parentId: Identifier?
    public var hasDisplay: Bool
    public var displayData: AdvancementDisplay?
    public var criteria: [Identifier]
    public var requirements: [[String]]
  }

  public struct AdvancementDisplay {
    public var title: ChatComponent
    public var description: ChatComponent
    public var icon: Slot
    public var frameType: Int
    public var flags: Int
    public var backgroundTexture: Identifier?
    public var xCoord: Float
    public var yCoord: Float
  }

  public struct AdvancementProgress {
    public var criteria: [Identifier: CriterionProgress]
  }

  public struct CriterionProgress {
    public var achieved: Bool
    public var dateOfAchieving: Int?
  }

  public init(from packetReader: inout PacketReader) throws {
    shouldReset = try packetReader.readBool()
    advancements = try Self.readAdvancements(from: &packetReader)
    advancementsToRemove = try Self.readAdvancementsToRemove(from: &packetReader)
    advancementProgresses = try Self.readAdvancementProgresses(from: &packetReader)
  }

  private static func readAdvancements(from packetReader: inout PacketReader) throws -> [Identifier: Advancement] {
    let mappingSize = try packetReader.readVarInt()
    var advancements: [Identifier: Advancement] = [:]
    for _ in 0..<mappingSize {
      let key = try packetReader.readIdentifier()

      // read advancement
      let hasParent = try packetReader.readBool()
      let parentId = hasParent ? try packetReader.readIdentifier() : nil
      let hasDisplay = try packetReader.readBool()
      var displayData: AdvancementDisplay?
      if hasDisplay {
        let title = try packetReader.readChat()
        let description = try packetReader.readChat()
        let icon = try packetReader.readSlot()
        let frameType = try packetReader.readVarInt()
        let flags = try packetReader.readInt() // 0x1: has background texture, 0x2: show toast, 0x4: hidden
        let backgroundTexture = flags & 0x1 == 0x1 ? try packetReader.readIdentifier() : nil
        let xCoord = try packetReader.readFloat()
        let yCoord = try packetReader.readFloat()
        displayData = AdvancementDisplay(
          title: title, description: description, icon: icon, frameType: frameType,
          flags: flags, backgroundTexture: backgroundTexture, xCoord: xCoord, yCoord: yCoord
        )
      }

      let numCriteria = try packetReader.readVarInt()
      var criteria: [Identifier] = []
      for _ in 0..<numCriteria {
        let criterion = try packetReader.readIdentifier()
        criteria.append(criterion)
      }

      let arrayLength = try packetReader.readVarInt()
      var requirements: [[String]] = []
      for _ in 0..<arrayLength {
        let arrayLength2 = try packetReader.readVarInt()
        var requirement: [String] = []
        for _ in 0..<arrayLength2 {
          let criterion = try packetReader.readString()
          requirement.append(criterion)
        }
        requirements.append(requirement)
      }

      let value = Advancement(
        hasParent: hasParent, parentId: parentId, hasDisplay: hasDisplay,
        displayData: displayData, criteria: criteria, requirements: requirements
      )
      advancements[key] = value
    }
    return advancements
  }

  private static func readAdvancementsToRemove(from packetReader: inout PacketReader) throws -> [Identifier] {
    let listSize = try packetReader.readVarInt()
    var advancementsToRemove: [Identifier] = []
    for _ in 0..<listSize {
      let identifier = try packetReader.readIdentifier()
      advancementsToRemove.append(identifier)
    }
    return advancementsToRemove
  }

  private static func readAdvancementProgresses(from packetReader: inout PacketReader) throws -> [Identifier: AdvancementProgress] {
    let progressSize = try packetReader.readVarInt()
    var progressMapping: [Identifier: AdvancementProgress] = [:]
    for _ in 0..<progressSize {
      let key = try packetReader.readIdentifier()

      // read advancement progress
      let size = try packetReader.readVarInt()
      var criteria: [Identifier: CriterionProgress] = [:]
      for _ in 0..<size {
        let identifier = try packetReader.readIdentifier()

        // read criterion progress
        let achieved = try packetReader.readBool()
        let dateOfAchieving = try achieved ? packetReader.readLong() : nil

        let progress = CriterionProgress(achieved: achieved, dateOfAchieving: dateOfAchieving)
        criteria[identifier] = progress
      }

      let advancementProgress = AdvancementProgress(criteria: criteria)
      progressMapping[key] = advancementProgress
    }
    return progressMapping
  }
}
