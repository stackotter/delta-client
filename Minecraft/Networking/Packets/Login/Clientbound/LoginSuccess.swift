//
//  LoginSuccess.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 3/1/21.
//

import Foundation

struct LoginSuccess: Packet {
  typealias PacketType = LoginSuccess
  static let id: Int = 0x02
  
  var uuid: UUID
  var username: String
  
  static func from(_ packetReader: inout PacketReader) -> LoginSuccess {
    let uuid = packetReader.readUUID()
    let username = packetReader.readString()
    let packet = LoginSuccess(uuid: uuid, username: username)
    return packet
  }
}

