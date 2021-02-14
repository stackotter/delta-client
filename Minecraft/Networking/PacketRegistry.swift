//
//  PacketRegistry.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/2/21.
//

import Foundation
import os

class PacketRegistry {
  var clientboundPackets: [PacketState: [Int: ClientboundPacket.Type]] = [
    .handshaking: [:],
    .status: [:],
    .login: [:],
    .play: [:]
  ]
  
//  var serverboundPackets: [PacketState: [Int: ServerBoundPacket]]
  
  enum PacketState {
    case handshaking
    case status
    case login
    case play
  }
  
  static func createDefault() -> PacketRegistry {
    let registry = PacketRegistry()
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
      DeclareRecipesPacket.self,
      TagsPacket.self
    ], toState: .play)
    return registry
  }
  
  func addClientboundPackets(_ packets: [ClientboundPacket.Type], toState state: PacketState) {
    for packet in packets {
      addClientboundPacket(packet, toState: state)
    }
  }
  
  func addClientboundPacket(_ packet: ClientboundPacket.Type, toState state: PacketState) {
    let id = packet.id
    clientboundPackets[state]![id] = packet
  }
  
  func getClientboundPacketType(withId id: Int, andState state: PacketState) -> ClientboundPacket.Type? {
    return clientboundPackets[state]?[id]
  }
  
  func handlePacket(_ reader: inout PacketReader, forServer server: Server, inState state: PacketState) throws {
    guard let packetType = getClientboundPacketType(withId: reader.packetId, andState: state) else {
      Logger.debug("packet not handled")
      return
    }
    
    let packet = try packetType.init(fromReader: &reader)
    try packet.handle(for: server)
  }
}
