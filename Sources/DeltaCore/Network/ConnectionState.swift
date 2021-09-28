//
//  File.swift
//  
//
//  Created by Rohan van Klinken on 27/6/21.
//

import Foundation

extension ServerConnection {
  public enum State {
    case idle
    case connecting
    case handshaking
    case status
    case login
    case play
    case disconnected
    
    public var packetState: PacketState? {
      switch self {
        case .handshaking:
          return .handshaking
        case .status:
          return .status
        case .login:
          return .login
        case .play:
          return .play
        default:
          return nil
      }
    }
  }
}
