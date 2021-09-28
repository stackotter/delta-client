import Foundation

public protocol NetworkLayer: InboundNetworkLayer, OutboundNetworkLayer { }

extension NetworkLayer {
  public func handleInbound(_ buffer: Buffer) {
    inboundSuccessor?.handleInbound(buffer)
  }
  
  public func handleOutbound(_ buffer: Buffer) {
    outboundSuccessor?.handleOutbound(buffer)
  }
}
