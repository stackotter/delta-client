//
//  NetworkLayer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation

protocol NetworkLayer: InboundNetworkLayer, OutboundNetworkLayer {
  
}

extension NetworkLayer {
  func handleInbound(_ buffer: Buffer) {
    inboundSuccessor?.handleInbound(buffer)
  }
  
  func handleOutbound(_ buffer: Buffer) {
    outboundSuccessor?.handleOutbound(buffer)
  }
}
