import Foundation

// TODO: get rid of successor and predecessor, use a list instead, this means layers can be structs

public class NetworkStack {
  private var ioThread: DispatchQueue
  public private(set) var outboundThread: DispatchQueue // TODO: threads should be private
  public private(set) var inboundThread: DispatchQueue
  
  private var host: String
  private var port: UInt16
  
  private var eventBus: EventBus
  
  // MARK: Network Layers
  
  public private(set) var socketLayer: SocketLayer
  public private(set) var encryptionLayer: EncryptionLayer
  public private(set) var packetLayer: PacketLayer
  public private(set) var compressionLayer: CompressionLayer
  public private(set) var protocolLayer: ProtocolLayer
  
  // MARK: Init
  
  public init(_ host: String, _ port: UInt16, eventBus: EventBus) {
    self.host = host
    self.port = port
    self.eventBus = eventBus
    
    ioThread = DispatchQueue(label: "networkIO")
    inboundThread = DispatchQueue(label: "networkHandlingInbound")
    outboundThread = DispatchQueue(label: "networkHandlingOutbound")
    
    // create layers
    socketLayer = SocketLayer(host, port, inboundThread: inboundThread, ioThread: ioThread, eventBus: eventBus)
    encryptionLayer = EncryptionLayer()
    packetLayer = PacketLayer()
    compressionLayer = CompressionLayer()
    protocolLayer = ProtocolLayer(outboundThread: outboundThread)
    
    // setup inbound flow
    socketLayer.inboundSuccessor = encryptionLayer
    encryptionLayer.inboundSuccessor = packetLayer
    packetLayer.inboundSuccessor = compressionLayer
    compressionLayer.inboundSuccessor = protocolLayer
    
    // setup outbound flow
    protocolLayer.outboundSuccessor = compressionLayer
    compressionLayer.outboundSuccessor = packetLayer
    packetLayer.outboundSuccessor = encryptionLayer
    encryptionLayer.outboundSuccessor = socketLayer
  }
  
  // MARK: Lifecycle
  
  public func connect() {
    socketLayer.connect()
  }
  
  public func disconnect() {
    socketLayer.disconnect()
  }
  
  public func reconnect() {
    disconnect()
    
    // remake socket layer
    let socketLayerSuccessor = socketLayer.inboundSuccessor
    socketLayer = SocketLayer(host, port, inboundThread: inboundThread, ioThread: ioThread, eventBus: eventBus)
    socketLayer.inboundSuccessor = socketLayerSuccessor
    if var outboundPredecessor = socketLayer.inboundSuccessor as? OutboundNetworkLayer {
      outboundPredecessor.outboundSuccessor = socketLayer
    }
    
    connect()
  }
  
  // MARK: Packets
  
  public func setPacketHandler(_ handler: @escaping (ProtocolLayer.Output) -> Void) {
    protocolLayer.handler = handler
  }
  
  public func sendPacket(_ packet: ServerboundPacket) {
    protocolLayer.send(packet)
  }
}
