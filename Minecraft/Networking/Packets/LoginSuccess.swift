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
  
  static func from(_ packetReader: PacketReader) throws -> LoginSuccess? {
    var mutableReader = packetReader
    let uuid = mutableReader.readUUID()
    let username = mutableReader.readString()
    let packet = LoginSuccess(uuid: uuid, username: username)
    return packet
  }
}

