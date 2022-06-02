import Foundation

/// Splits a stream of bytes into Minecraft packets.
public struct PacketLayer {
  // MARK: Private properties
  
  /// Keeps track of the state of the receiver across calls to ``processInbound(_:)``.
  private var receiveState = ReceiveState()
  
  /// The state of the receiver.
  private struct ReceiveState {
    var lengthBytes: [UInt8] = []
    var length: Int?
    var packet: [UInt8] = []
  }
  
  // MARK: Init
  
  /// Creates a new packet layer.
  public init() {}
  
  // MARK: Public methods
  
  /// Processes an inbound buffer.
  ///
  /// For each packet contained within the buffer it calls ``packetHandler``. It also works if
  /// packets are split across multiple packets.
  /// - Parameter buffer: The buffer of data received from the server.
  /// - Returns: An array of buffers, each representing a Minecraft packet.
  public mutating func processInbound(_ buffer: Buffer) throws -> [Buffer] {
    var packets: [Buffer] = []
    
    var buffer = buffer // mutable copy
    while true {
      if buffer.remaining == 0 {
        break
      }

      guard let length = receiveState.length else {
        receiveState.length = try readLength(from: &buffer)
        continue
      }
      
      if length == 0 {
        log.trace("Received empty packet")
        receiveState = ReceiveState()
      } else if buffer.remaining != 0 {
        let byteCount = min(buffer.remaining, length - receiveState.packet.count)
        let bytes = try buffer.readBytes(byteCount)
        receiveState.packet.append(contentsOf: bytes)
          
        if receiveState.packet.count == length {
          packets.append(Buffer(receiveState.packet))
          receiveState = ReceiveState()
        }
      }
    }
    
    return packets
  }
  
  /// Wraps an outbound packet into a regularly formatted Minecraft packet (without compression and encryption).
  ///
  /// It prefixes the buffer with its length as a var int.
  public func processOutbound(_ buffer: Buffer) -> Buffer {
    var packed = Buffer()
    packed.writeVarInt(Int32(buffer.length))
    packed.writeBytes(buffer.bytes)
    return packed
  }

  // MARK: Private methods

  private mutating func readLength(from buffer: inout Buffer) throws -> Int? {
    while buffer.remaining != 0 {
      let byte = try buffer.readByte()
      receiveState.lengthBytes.append(byte)
      if byte & 0x80 == 0x00 {
        break
      }
    }
    
    if let lastLengthByte = receiveState.lengthBytes.last {
      if lastLengthByte & 0x80 == 0x00 {
        // Using standalone implementation of varint decoding to hopefully reduce networking overheads slightly?
        var length = 0
        for i in 0..<receiveState.lengthBytes.count {
          let byte = receiveState.lengthBytes[i]
          length += Int(byte & 0x7f) << (i * 7)
        }
        return length
      }
    }

    return nil
  }
}
