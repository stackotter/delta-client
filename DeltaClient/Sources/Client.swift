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
    guard let account = self.managers.configManager.getSelectedAccount() else {
      self.managers.configManager.logout()
      DeltaClientApp.triggerError("you must create an account before you can join servers")
      return
    }
    
    if let mojangAccount = account as? MojangAccount {
      self.managers.configManager.refreshMojangAccount(account: mojangAccount, success: {
        self.server.login()
      })
    } else {
      self.server.login()
    }
  }
  
  func quit() {
    server.connection.close()
  }
  
  // Commands interface
  
  // TODO: remove CLI
  // swiftlint:disable function_body_length
  func runCommand(_ command: String) {
    log.info("Running command `\(command)`")
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
              log.info("swung off hand")
              return
            }
          }
          let packet = AnimationServerboundPacket(hand: .mainHand)
          server.sendPacket(packet)
          log.info("swung main hand")
        case "tablist":
          log.info("-- BEGIN TABLIST --")
          for playerInfo in server.tabList.players {
            log.info("[\(playerInfo.value.displayName?.toText() ?? playerInfo.value.name)] ping=\(playerInfo.value.ping)ms")
          }
          log.info("-- END TABLIST --")
        case "getblock":
          if options.count == 3 {
            guard
              let x = Int(options[0]),
              let y = Int(options[1]),
              let z = Int(options[2])
            else {
              log.info("x y z must be integers")
              return
            }
            let position = Position(x: x, y: y, z: z)
            let block = server.world?.getBlock(at: position) ?? 0
            log.info("block has state \(block)")
          } else {
            log.info("usage: getblock x y z")
          }
        case "getlight":
          if options.count == 3 {
            guard
              let x = Int(options[0]),
              let y = Int(options[1]),
              let z = Int(options[2])
            else {
              log.info("x y z must be integers")
              return
            }
            let position = Position(x: x, y: y, z: z)
            if let lighting = server.world?.chunk(at: position.chunk)?.lighting {
              log.info("skyLight: \(lighting.getSkyLightLevel(at: position))")
              log.info("blockLight: \(lighting.getBlockLightLevel(at: position))")
            }
          } else {
            log.info("usage: getlight x y z")
          }
        case "chat":
          let message = options.joined(separator: " ")
          let packet = ChatMessageServerboundPacket(message: message)
          server.sendPacket(packet)
        default:
          log.warning("invalid command")
      }
    }
  }
  // swiftlint:enable function_body_length
}
