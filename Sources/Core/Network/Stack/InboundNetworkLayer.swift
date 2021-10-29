import Foundation

public protocol InboundNetworkLayer {
  var inboundSuccessor: InboundNetworkLayer? { get set }
  
  func handleInbound(_ buffer: Buffer)
}
