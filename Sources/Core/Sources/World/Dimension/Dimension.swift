// TODO: Update the property names once I understand what they each actually do
public struct Dimension {
  public var identifier: Identifier
  public var ambientLight: Float
  public var infiniburn: Identifier?
  public var fixedTime: Int?
  public var logicalHeight: Int
  public var isNatural: Bool
  public var hasCeiling: Bool
  public var hasSkylight: Bool
  public var shrunk: Bool
  public var ultrawarm: Bool
  public var hasRaids: Bool
  public var respawnAnchorWorks: Bool
  public var bedWorks: Bool
  public var piglinSafe: Bool

  public static let overworld = Dimension(
    identifier: Identifier(name: "overworld"),
    ambientLight: 0,
    infiniburn: Identifier(name: "infiniburn_overworld"),
    fixedTime: nil,
    logicalHeight: 256,
    isNatural: true,
    hasCeiling: false,
    hasSkylight: true,
    shrunk: false,
    ultrawarm: false,
    hasRaids: true,
    respawnAnchorWorks: false,
    bedWorks: true,
    piglinSafe: false
  )

  public init(identifier: Identifier, ambientLight: Float, infiniburn: Identifier? = nil, fixedTime: Int? = nil, logicalHeight: Int, isNatural: Bool, hasCeiling: Bool, hasSkylight: Bool, shrunk: Bool, ultrawarm: Bool, hasRaids: Bool, respawnAnchorWorks: Bool, bedWorks: Bool, piglinSafe: Bool) {
    self.identifier = identifier
    self.ambientLight = ambientLight
    self.infiniburn = infiniburn
    self.fixedTime = fixedTime
    self.logicalHeight = logicalHeight
    self.isNatural = isNatural
    self.hasCeiling = hasCeiling
    self.hasSkylight = hasSkylight
    self.shrunk = shrunk
    self.ultrawarm = ultrawarm
    self.hasRaids = hasRaids
    self.respawnAnchorWorks = respawnAnchorWorks
    self.bedWorks = bedWorks
    self.piglinSafe = piglinSafe
  }

  public init(from compound: NBT.Compound) throws {
    identifier = try Identifier(compound.get("name"))
    ambientLight = try compound.get("ambient_light")

    let infiniburn: String = try compound.get("infiniburn")
    self.infiniburn = infiniburn == "" ? nil : try Identifier(infiniburn)

    let fixedTime: Int64? = try? compound.get("fixed_time")
    self.fixedTime = fixedTime.map(Int.init)

    let isNatural: UInt8 = try compound.get("natural")
    self.isNatural = isNatural == 1
    let hasCeiling: UInt8 = try compound.get("has_ceiling")
    self.hasCeiling = hasCeiling == 1
    let hasSkylight: UInt8 = try compound.get("has_skylight")
    self.hasSkylight = hasSkylight == 1
    let shrunk: UInt8 = try compound.get("shrunk")
    self.shrunk = shrunk == 1
    let ultrawarm: UInt8 = try compound.get("ultrawarm")
    self.ultrawarm = ultrawarm == 1
    let hasRaids: UInt8 = try compound.get("has_raids")
    self.hasRaids = hasRaids == 1
    let respawnAnchorWorks: UInt8 = try compound.get("respawn_anchor_works")
    self.respawnAnchorWorks = respawnAnchorWorks == 1
    let bedWorks: UInt8 = try compound.get("bed_works")
    self.bedWorks = bedWorks == 1
    let piglinSafe: UInt8 = try compound.get("piglin_safe")
    self.piglinSafe = piglinSafe == 1
    let logicalHeight: Int32 = try compound.get("logical_height")
    self.logicalHeight = Int(logicalHeight)
  }
}