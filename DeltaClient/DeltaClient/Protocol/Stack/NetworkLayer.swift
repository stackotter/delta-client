//
//  NetworkLayer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation

class NetworkLayer: InboundNetworkLayer, OutboundNetworkLayer {
  var inboundSuccessor: InboundNetworkLayer?
  var outboundSuccessor: OutboundNetworkLayer?
  
  func handleInbound(_ buffer: Buffer) {
    if let next = inboundSuccessor {
      next.handleInbound(buffer)
    }
  }
  
  func handleOutbound(_ buffer: Buffer) {
    if let next = outboundSuccessor {
      next.handleOutbound(buffer)
    }
  }
}
