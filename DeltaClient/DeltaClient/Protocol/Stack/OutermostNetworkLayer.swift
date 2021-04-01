//
//  OutermostNetworkLayer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation

protocol OutermostNetworkLayer: OutboundNetworkLayer {
  var inboundSuccessor: InboundNetworkLayer? { get set }
  var thread: DispatchQueue { get set }
  
  func connect()
  
  func disconnect()
}
