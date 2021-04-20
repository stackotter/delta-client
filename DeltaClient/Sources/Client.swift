//
//  Client.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation


class Client {
  var server: Server
  var managers: Managers
  
  // Init
  
  init(managers: Managers, serverDescriptor: ServerDescriptor) {
    self.managers = managers
    self.server = Server(descriptor: serverDescriptor, managers: managers)
  }
  
  // Server interaction
  
  func play() {
    self.managers.configManager.refreshAccessToken(success: {
      self.server.login()
    })
  }
  
  func quit() {
    server.connection.close()
  }
  
  // Commands interface
  
  // TODO: create CLI class
  // swiftlint:disable function_body_length
  func runCommand(_ command: String) {
    let logger = Logger(name: "CLI")
    logger.info("running command `\(command)`")
    let parts = command.split(separator: " ")
    if let command = parts.first {
      let options = parts.dropFirst().map {
        return String($0)
      }
      switch command {
        case "say":
          let message = options.joined(separator: " ")
          let packet = ChatMessageServerboundPacket(message: message)
          server.sendPacket(packet)
        case "swing":
          if !options.isEmpty {
            if options.first == "offhand" {
              let packet = AnimationServerboundPacket(hand: .offHand)
              server.sendPacket(packet)
              Logger.info("swung off hand")
              return
            }
          }
          let packet = AnimationServerboundPacket(hand: .mainHand)
          server.sendPacket(packet)
          Logger.info("swung main hand")
        case "tablist":
          Logger.info("-- BEGIN TABLIST --")
          for playerInfo in server.tabList.players {
            Logger.info("[\(playerInfo.value.displayName?.toText() ?? playerInfo.value.name)] ping=\(playerInfo.value.ping)ms")
          }
          Logger.info("-- END TABLIST --")
        case "getblock":
          if options.count == 3 {
            guard
              let x = Int(options[0]),
              let y = Int(options[1]),
              let z = Int(options[2])
            else {
              Logger.info("x y z must be integers")
              return
            }
            let position = Position(x: x, y: y, z: z)
            let block = server.world?.getBlock(at: position) ?? 0
            Logger.info("block has state \(block)")
          } else {
            Logger.info("usage: getblock x y z")
          }
        case "getlight":
          if options.count == 3 {
            guard
              let x = Int(options[0]),
              let y = Int(options[1]),
              let z = Int(options[2])
            else {
              Logger.info("x y z must be integers")
              return
            }
            let position = Position(x: x, y: y, z: z)
            if let lighting = server.world?.lighting[position.chunkPosition] {
              logger.info("skyLight: \(lighting.getSkyLightLevel(at: position))")
              logger.info("blockLight: \(lighting.getBlockLightLevel(at: position))")
            }
          } else {
            Logger.info("usage: getlight x y z")
          }
        default:
          Logger.warn("invalid command")
      }
    }
  }
  // swiftlint:enable function_body_length
}
