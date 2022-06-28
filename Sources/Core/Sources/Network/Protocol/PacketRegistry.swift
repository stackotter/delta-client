import Foundation

/// Stores the clientbound packet types for a given protocol version and assigns them ids.
///
/// Packets are also grouped by connection state. For example, packet 0x01 in the handshaking
/// state is usually differnet to packet 0x01 in the status state.
public struct PacketRegistry {
  /// The client bound packets of this protocol.
  public var clientboundPackets: [PacketState: [Int: ClientboundPacket.Type]] = [
    .handshaking: [:],
    .status: [:],
    .login: [:],
    .play: [:]
  ]

  /// Creates an empty packet registry.
  public init() {}

  // swiftlint:disable function_body_length
  /// Creates the packet registry for the 1.16.1 protocol version.
  public static func create_1_16_1() -> PacketRegistry {
    var registry = PacketRegistry()

    registry.addClientboundPackets([
      StatusResponsePacket.self,
      PongPacket.self
    ], toState: .status)

    registry.addClientboundPackets([
      LoginDisconnectPacket.self,
      EncryptionRequestPacket.self,
      LoginSuccessPacket.self,
      SetCompressionPacket.self,
      LoginPluginRequestPacket.self,
      PlayDisconnectPacket.self
    ], toState: .login)

    registry.addClientboundPackets([
      SpawnEntityPacket.self,
      SpawnExperienceOrbPacket.self,
      SpawnLivingEntityPacket.self,
      SpawnPaintingPacket.self,
      SpawnPlayerPacket.self,
      EntityAnimationPacket.self,
      StatisticsPacket.self,
      AcknowledgePlayerDiggingPacket.self,
      BlockBreakAnimationPacket.self,
      BlockEntityDataPacket.self,
      BlockActionPacket.self,
      BlockChangePacket.self,
      BossBarPacket.self,
      ServerDifficultyPacket.self,
      ChatMessageClientboundPacket.self,
      MultiBlockChangePacket.self,
      TabCompleteClientboundPacket.self,
      DeclareCommandsPacket.self,
      WindowConfirmationClientboundPacket.self,
      CloseWindowClientboundPacket.self,
      WindowItemsPacket.self,
      SetSlotPacket.self,
      SetCooldownPacket.self,
      PluginMessagePacket.self,
      NamedSoundEffectPacket.self,
      PlayDisconnectPacket.self,
      EntityStatusPacket.self,
      ExplosionPacket.self,
      UnloadChunkPacket.self,
      ChangeGameStatePacket.self,
      OpenHorseWindowPacket.self,
      KeepAliveClientboundPacket.self,
      ChunkDataPacket.self,
      EffectPacket.self,
      ParticlePacket.self,
      UpdateLightPacket.self,
      JoinGamePacket.self,
      MapDataPacket.self,
      TradeListPacket.self,
      EntityPositionPacket.self,
      EntityPositionAndRotationPacket.self,
      EntityRotationPacket.self,
      EntityMovementPacket.self,
      VehicleMoveClientboundPacket.self,
      OpenBookPacket.self,
      OpenWindowPacket.self,
      OpenSignEditorPacket.self,
      CraftRecipeResponsePacket.self,
      PlayerAbilitiesPacket.self,
      CombatEventPacket.self,
      PlayerInfoPacket.self,
      FacePlayerPacket.self,
      PlayerPositionAndLookClientboundPacket.self,
      UnlockRecipesPacket.self,
      DestroyEntitiesPacket.self,
      RemoveEntityEffectPacket.self,
      ResourcePackSendPacket.self,
      RespawnPacket.self,
      EntityHeadLookPacket.self,
      SelectAdvancementTabPacket.self,
      WorldBorderPacket.self,
      CameraPacket.self,
      HeldItemChangePacket.self,
      UpdateViewPositionPacket.self,
      UpdateViewDistancePacket.self,
      SpawnPositionPacket.self,
      DisplayScoreboardPacket.self,
      EntityMetadataPacket.self,
      AttachEntityPacket.self,
      EntityVelocityPacket.self,
      EntityEquipmentPacket.self,
      SetExperiencePacket.self,
      UpdateHealthPacket.self,
      ScoreboardObjectivePacket.self,
      SetPassengersPacket.self,
      TeamsPacket.self,
      UpdateScorePacket.self,
      TimeUpdatePacket.self,
      TitlePacket.self,
      EntitySoundEffectPacket.self,
      SoundEffectPacket.self,
      StopSoundPacket.self,
      PlayerListHeaderAndFooterPacket.self,
      NBTQueryResponsePacket.self,
      CollectItemPacket.self,
      EntityTeleportPacket.self,
      AdvancementsPacket.self,
      EntityAttributesPacket.self,
      EntityEffectPacket.self,
      DeclareRecipesPacket.self,
      TagsPacket.self
    ], toState: .play)
    return registry
  }
  // swiftlint:enable function_body_length

  /// Adds an array of clientbound packets to the given connection state. Each packet is assigned the id which is stored as a static property on the type.
  public mutating func addClientboundPackets(_ packets: [ClientboundPacket.Type], toState state: PacketState) {
    for packet in packets {
      addClientboundPacket(packet, toState: state)
    }
  }

  /// Adds a clientbound packet to the given connection state. The packet is assigned the id which is stored in the static property `id`.
  public mutating func addClientboundPacket(_ packet: ClientboundPacket.Type, toState state: PacketState) {
    let id = packet.id
    if var packets = clientboundPackets[state] {
      packets[id] = packet
      clientboundPackets[state] = packets
    } else {
      clientboundPackets[state] = [id: packet]
    }
  }

  /// Gets the packet type for the requested packet id and connection state.
  public func getClientboundPacketType(withId id: Int, andState state: PacketState) -> ClientboundPacket.Type? {
    return clientboundPackets[state]?[id]
  }
}
