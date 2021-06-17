//
//  OutermostNetworkLayer.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 31/3/21.
//

import Foundation

protocol OutermostNetworkLayer: OutboundNetworkLayer {
  var inboundSuccessor: InboundNetworkLayer? { get set }
  var inboundThread: DispatchQueue { get set }
  var ioThread: DispatchQueue { get set }
  
  func connect()
  
  func disconnect()
}
