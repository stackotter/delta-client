//
//  PacketRegistry.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation

// TODO: Make PacketRegistry a singleton
public class PacketRegistry {
  public var clientboundPackets: [PacketState: [Int: ClientboundPacket.Type]] = [
    .handshaking: [:],
    .status: [:],
    .login: [:],
    .play: [:]
  ]
  
  // TODO: make this part of a static variable definition
  // swiftlint:disable function_body_length
  public static func create_1_16_1() -> PacketRegistry {
    let registry = PacketRegistry()
    
    registry.addClientboundPackets([
      StatusResponsePacket.self,
      PongPacket.self
    ], toState: .status)
    
    registry.addClientboundPackets([
      LoginDisconnectPacket.self,
      EncryptionRequestPacket.self,
      LoginSuccessPacket.self,
      SetCompressionPacket.self,
      LoginPluginRequestPacket.self
    ], toState: .login)
    
    registry.addClientboundPackets([
      SpawnEntityPacket.self,
      SpawnExperienceOrbPacket.self,
      SpawnLivingEntity.self,
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
      NBTQueryResponse.self,
      CollectItemPacket.self,
      EntityTeleportPacket.self,
      AdvancementsPacket.self,
      EntityProperties.self,
      EntityEffectPacket.self,
      DeclareRecipesPacket.self,
      TagsPacket.self
    ], toState: .play)
    return registry
  }
  // swiftlint:enable function_body_length
  
  // MARK: Helpers
  
  public func addClientboundPackets(_ packets: [ClientboundPacket.Type], toState state: PacketState) {
    for packet in packets {
      addClientboundPacket(packet, toState: state)
    }
  }
  
  public func addClientboundPacket(_ packet: ClientboundPacket.Type, toState state: PacketState) {
    let id = packet.id
    if var packets = clientboundPackets[state] {
      packets[id] = packet
      clientboundPackets[state] = packets
    } else {
      clientboundPackets[state] = [id: packet]
    }
  }
  
  public func getClientboundPacketType(withId id: Int, andState state: PacketState) -> ClientboundPacket.Type? {
    return clientboundPackets[state]?[id]
  }
}
