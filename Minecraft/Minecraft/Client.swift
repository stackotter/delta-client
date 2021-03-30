//
//  Client.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 12/1/21.
//

import Foundation
import os

// pretty much the backend class for the whole game
class Client {
  var state: ClientState = .idle
  var server: Server
  
  var managers: Managers
  
  enum ClientState {
    case idle
    case initialising
    case connecting
    case play
  }
  
  init(managers: Managers, serverInfo: ServerInfo) {
    self.managers = managers
    
    self.server = Server(withInfo: serverInfo, managers: managers)
  }
  
  // TEMP
  func play() {
    server.login()
  }
  
  func runCommand(_ command: String) {
    let logger = Logger(subsystem: "Minecraft", category: "commands")
    logger.log("running command `\(command)`")
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
          if options.count > 0 {
            if options.first == "offhand" {
              let packet = AnimationServerboundPacket(hand: .offHand)
              server.sendPacket(packet)
              Logger.log("swung off hand")
              return
            }
          }
          let packet = AnimationServerboundPacket(hand: .mainHand)
          server.sendPacket(packet)
          Logger.log("swung main hand")
        case "tablist":
          Logger.log("-- BEGIN TABLIST --")
          for playerInfo in server.tabList.players {
            Logger.log("[\(playerInfo.value.displayName?.toText() ?? playerInfo.value.name)] ping=\(playerInfo.value.ping)ms")
          }
          Logger.log("-- END TABLIST --")
        case "getblock":
          if options.count == 3 {
            guard
              let x = Int(options[0]),
              let y = Int(options[1]),
              let z = Int(options[2])
            else {
              Logger.log("x y z must be integers")
              return
            }
            let position = Position(x: x, y: y, z: z)
            let block = server.currentWorld.getBlock(at: position)
            Logger.log("block has state \(block)")
          } else {
            Logger.log("usage: getblock x y z")
          }
        case "testc":
          var dataArray: [UInt64] = [1234586777848713489, 1229782943097032977, 1229782938533634321, 1244138162077442321, 1244190938635575569, 1460310944174444817, 6148839631242727697, 6148839631242727697, 6147713731335885073, 6129699332826403089, 5841468956674691345, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1230083173927424273, 1230680140021895441, 1244190938904006929, 1460363720749355281, 1460363720749355281, 1460363720731463953, 6148892407800860945, 6148839631242727697, 6147713731335885073, 6143210131708514577, 1229782938247303441, 1231278274061078801, 1231278274061078801, 1231278274061078801, 1231190313130856721, 1229782938247303441, 1231583938579861777, 1258605536344150289, 1690947802036834577, 1690947801768333585, 8608424052833456401, 8594068829021212945, 1460363720731463953, 6148558156266017041, 6143210131797971217, 4918231034495394065, 1231278275492733201, 1253796272287408401, 1253796272197931281, 1253796272197931281, 1231278274061078801, 1231190313130856721, 1231583938579861777, 1690951100571652369, 1690951100302168337, 8608476829391589649, 8608476829391589649, 8607576329368441105, 8594065530486329617, 1459589664831840529, 1229782942828601889, 1229783011548078625, 1230082078710833697, 1234585609618727441, 1234585605323759889, 1234585605055324689, 1234585605055324689, 1230064413224014100, 1231583938293600529, 1690951100285391121, 1690951100285391121, 8608473530856706321, 8608473530856706321, 8607523552819220753, 8595261799146295569, 1231876408387113233, 1229906083835945233, 1229782938533634577, 1230064413510345233, 1230082005696389393, 1234585605037457681, 1234585605055324689, 1230082005427954193, 1229782938247368980, 1231583938293600529, 1258605536057823505, 1690944503215624465, 1690944503215624465, 8608367977740648721, 8579657530124878097, 1229782938256249873, 1229785274710071569, 1229820467671734593, 1229785274743263553, 1229782938247512388, 12295127222696625220, 12295408697673810241, 1230064413224042769, 1229782938247303441, 1229782938247303444, 1229783075686256913, 1229782938247303441, 1229782938247303441, 1229782938250645777, 1229782938250658065, 1229782938250658833, 1229785274713195585, 1230383418195614017, 1230383418198759745, 1229820468262093892, 12297660644089676868, 12297818827161617476, 12295285552371012676, 12295127222696612164, 1229782938247303441, 1229782938247303441, 1229785283299447057, 1229820467671535889, 1230383271596069137, 1239390470854152465, 1239388271830909201, 1238790137505399825, 1229785274712867905, 1230383418197689409, 1230383418198737985, 1229820468262093892, 12297818973764076612, 12302603902338221124, 12302603901765502020, 12297660497487008836, 1229782938247303441, 1229782938247303441, 1229820467671535889, 1230383417624957201, 1239390608289763601, 1239390470850810129, 1383505658926874897, 1383503459903619345, 1238790137502254097, 1229820468242170897, 1229820468244268097, 1229820468244268100, 12295127231860327492, 12297941972497482820, 12302445572091089988, 12254594826050277764, 1229782938247303441, 1229782938247303441, 1229785284158230801, 1229820459135275281, 1239390470904484113, 1239390470854152465, 1383503459903410449, 1383468275531321617, 1238790137502044433, 1229782938247443251, 1229782938817868595, 1229782938819838771, 1229782938283557956, 1878301287165633604, 1229782979478952068, 1229782979468925057, 1229782938247303441, 1229782938247303441, 1229782951991185682, 1229782939106283794, 1229782939106296081, 1230381072626499857, 1230381072576168209, 1238790137502241041, 1229782938247443217, 1229782938249540403, 1229782938249540403, 1229782938247443251, 1229782938408362803, 1229782940824283809, 1229782979478988817, 1229782979478360337, 1229782938247303441, 1229782938247303441, 1229782951991185698, 1229782939106296082, 1229782939106296081, 1229782938300989713, 1229782938250658065, 1229782938247500049, 1229782938247435025, 1229782938249540403, 1229782938249540403, 1229782938247443251, 1229782938408362803, 1229782938408364705, 1229782940824281361, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782953417249058, 1229782940532347154, 1229782938300977425, 1229782938300977425, 1229782938247500049, 1229782938247303441, 1229782938247303441, 1229782938247435025, 1229782938247312186, 1229782938247340858, 1229782938247932586, 1229782938257369761, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782940532150546, 1229782940532150545, 1229782940532150545, 1229782940394787089, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303594, 1229782938247303585, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1263278462757572881, 1263278462757572881, 1229782940394787089, 1229782940394787089, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 3535625947460997393, 3535625947460997393, 1229782938247303441, 1261308135638896913, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 1229782938247303441, 3535625947460997393, 3535625947460997393, 3679741135536853265]
          let bitsPerBlock = 4
          var blocks: [UInt16] = [UInt16](repeating: 0, count: 4096)
          unpack_chunk(&dataArray, Int32(dataArray.count), Int32(bitsPerBlock), &blocks)
          Logger.log("\(blocks[0]) \(blocks[4095])")
        default:
          Logger.log("invalid command")
      }
    }
  }
}