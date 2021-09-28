import Foundation

public protocol InnermostNetworkLayer: InboundNetworkLayer {
  associatedtype Packet
  associatedtype Output
  
  var outboundSuccessor: OutboundNetworkLayer? { get set }
  var handler: ((Output) -> Void)? { get set }
  
  func send(_ packet: Packet)
}
