import Foundation

public protocol OutermostNetworkLayer: OutboundNetworkLayer {
  var inboundSuccessor: InboundNetworkLayer? { get set }
  
  func connect()
  
  func disconnect()
}
