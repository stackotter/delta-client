import Foundation

public protocol OutboundNetworkLayer {
  var outboundSuccessor: OutboundNetworkLayer? { get set }
  
  func handleOutbound(_ buffer: Buffer)
}
