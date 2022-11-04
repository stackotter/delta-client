#if canImport(WinSDK)
import WinSDK.WinSock2
#endif
import Foundation

public struct Socket: Sendable, Hashable {
  public enum SocketType {
    case tcp
    case udp
  }

  public enum AddressFamily {
    case ip4
    case ip6
    case unix
  }

  public enum Address: Hashable {
    case ip4(String, UInt16)
    case ip6(String, UInt16)
    case unix(String)

    init(from addr: sockaddr_storage) throws {
      switch Int32(addr.ss_family) {
        case AF_INET:
          var addr_in: sockaddr_in = Socket.unsafeCast(addr)
          let maxLength = socklen_t(INET_ADDRSTRLEN)
          let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(maxLength))
          try Socket.inet_ntop(AF_INET, &addr_in.sin_addr, buffer, maxLength)
          self = .ip4(String(cString: buffer), UInt16(addr_in.sin_port).byteSwapped)
        case AF_INET6:
          var addr_in6: sockaddr_in6 = Socket.unsafeCast(addr)
          let maxLength = socklen_t(INET6_ADDRSTRLEN)
          let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(maxLength))
          try Socket.inet_ntop(AF_INET6, &addr_in6.sin6_addr, buffer, maxLength)
          self = .ip6(String(cString: buffer), UInt16(addr_in6.sin6_port).byteSwapped)
        case AF_UNIX:
          var addr_un: sockaddr_un = Socket.unsafeCast(addr)
          self = withUnsafePointer(to: &addr_un.sun_path.0) {
            return .unix(String(cString: $0))
          }
        default:
          throw SocketError.unsupportedAddressFamily(rawValue: Int(addr.ss_family))
      }
    }

    func toNative() throws -> sockaddr_storage {
      switch self {
        case .ip4(let host, let port):
          var address = Socket.makeAddressINET(port: port)
          address.sin_addr = try Socket.makeInAddr(fromIP4: host)
          return Socket.unsafeCast(address)
        case .ip6(let host, let port):
          var address = Socket.makeAddressINET6(port: port)
          address.sin6_addr = try Socket.makeInAddr(fromIP6: host)
          return Socket.unsafeCast(address)
        case .unix(let path):
          return Socket.unsafeCast(makeAddressUnix(path: path))
      }
    }

    var nativeSize: Int {
      switch self {
        case .ip4: return MemoryLayout<sockaddr_in>.size
        case .ip6: return MemoryLayout<sockaddr_in6>.size
        case .unix: return MemoryLayout<sockaddr_un>.size
      }
    }
  }

  public struct Flags: OptionSet {
    public var rawValue: Int32

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public static let nonBlocking = Flags(rawValue: O_NONBLOCK)
  }

  public struct FileDescriptor: RawRepresentable, Sendable, Hashable {
    public let rawValue: Socket.FileDescriptorType

    public init(rawValue: Socket.FileDescriptorType) {
      self.rawValue = rawValue
    }
  }

  // MARK: Properties

  public let file: FileDescriptor

  // MARK: Init

  public init(_ addressFamily: AddressFamily, _ type: SocketType) throws {
    let descriptor = FileDescriptor(rawValue: Socket.socket(addressFamily.rawValue, type.rawValue, 0))
    guard descriptor != .invalid else {
      throw SocketError.actionFailed("create")
    }
    self.file = descriptor
  }

  // MARK: Flags

  public var flags: Flags {
    get throws {
      let flags = Socket.fcntl(file.rawValue, F_GETFL)
      if flags == -1 {
        throw SocketError.actionFailed("get flags")
      }
      return Flags(rawValue: flags)
    }
  }

  public func setFlags(_ flags: Flags) throws {
    if Socket.fcntl(file.rawValue, F_SETFL, flags.rawValue) == -1 {
      throw SocketError.actionFailed("set flags")
    }
  }

  // MARK: Options

  public func setValue<O: SettableSocketOption>(_ value: O.Value, for option: O) throws {
    var value = option.makeSocketValue(from: value)
    let length = socklen_t(MemoryLayout<O.SocketValue>.size)
    guard Socket.setsockopt(file.rawValue, option.getLevel(), option.name, &value, length) >= 0 else {
      throw SocketError.actionFailed("set option")
    }
  }

  public func getValue<O: GettableSocketOption>(for option: O) throws -> O.Value {
    let valuePtr = UnsafeMutablePointer<O.SocketValue>.allocate(capacity: 1)
    var length = socklen_t(MemoryLayout<O.SocketValue>.size)
    guard Socket.getsockopt(file.rawValue, option.getLevel(), option.name, valuePtr, &length) >= 0 else {
      throw SocketError.actionFailed("get option")
    }
    return option.makeValue(from: valuePtr.pointee)
  }

  // MARK: Listening

  public func bind(to address: Address) throws {
    let storage = try address.toNative()
    var addr: sockaddr = Self.unsafeCast(storage)
    let result = Socket.bind(file.rawValue, &addr, socklen_t(address.nativeSize))
    guard result >= 0 else {
      throw SocketError.actionFailed("bind")
    }
  }

  public func listen(maxPendingConnection: Int32 = SOMAXCONN) throws {
    if Socket.listen(file.rawValue, maxPendingConnection) == -1 {
      let error = SocketError.actionFailed("listen")
      try close()
      throw error
    }
  }

  public func accept() throws -> (file: FileDescriptor, address: Address) {
    var address = sockaddr_storage()
    var len = socklen_t(MemoryLayout<sockaddr_storage>.size)

    let newFile = withUnsafeMutablePointer(to: &address) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        FileDescriptor(rawValue: Socket.accept(file.rawValue, $0, &len))
      }
    }

    guard newFile != .invalid else {
      if errno == EWOULDBLOCK {
        throw SocketError.blocked
      } else {
        throw SocketError.actionFailed("accept")
      }
    }

    return (newFile, try Address(from: address))
  }

  // MARK: Socket names

  public func remotePeer() throws -> Address {
    var addr = sockaddr_storage()
    var len = socklen_t(MemoryLayout<sockaddr_storage>.size)

    let result = withUnsafeMutablePointer(to: &addr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        Socket.getpeername(file.rawValue, $0, &len)
      }
    }
    if result != 0 {
      throw SocketError.actionFailed("get peer name")
    }
    return try Address(from: addr)
  }

  public func sockname() throws -> Address {
    var addr = sockaddr_storage()
    var len = socklen_t(MemoryLayout<sockaddr_storage>.size)

    let result = withUnsafeMutablePointer(to: &addr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        Socket.getsockname(file.rawValue, $0, &len)
      }
    }
    if result != 0 {
      throw SocketError.actionFailed("get socket name")
    }
    return try Address(from: addr)
  }

  static func makeInAddr(fromIP4 address: String) throws -> in_addr {
    var addr = in_addr()
    guard address.withCString({ Socket.inet_pton(AF_INET, $0, &addr) }) == 1 else {
      throw SocketError.actionFailed("convert ipv4 address to in_addr (pton)")
    }
    return addr
  }

  static func makeInAddr(fromIP6 address: String) throws -> in6_addr {
    var addr = in6_addr()
    guard address.withCString({ Socket.inet_pton(AF_INET6, $0, &addr) }) == 1 else {
      throw SocketError.actionFailed("convert ipv6 address to in6_addr (pton)")
    }
    return addr
  }

  // MARK: Connecting

  public func connect(to address: Address) throws {
    var addr = try address.toNative()
    let result = withUnsafePointer(to: &addr) {
      $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        Socket.connect(file.rawValue, $0, socklen_t(address.nativeSize))
      }
    }
    guard result >= 0 || errno == EISCONN else {
      if errno == EINPROGRESS {
        throw SocketError.blocked
      } else {
        throw SocketError.actionFailed("connect")
      }
    }
  }

  // MARK: IO

  public func recvFrom(atMost length: Int) throws -> (data: [UInt8], address: Address) {
    var sender = sockaddr_storage()
    var sockaddrLength = UInt32(MemoryLayout<sockaddr_storage>.stride)
    let bytes = try [UInt8](unsafeUninitializedCapacity: length) { buffer, count in
      withUnsafeMutablePointer(to: &sender) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { pointer in
          count = recvfrom(file.rawValue, buffer.baseAddress, length, 0, pointer, &sockaddrLength)
        }
      }

      guard count > 0 else {
        if errno == EWOULDBLOCK {
          throw SocketError.blocked
        } else if errno == EBADF || count == 0 {
          throw SocketError.disconnected
        } else {
          throw SocketError.actionFailed("receive")
        }
      }
    }
    return (bytes, try Address(from: sender))
  }

  public func read(atMost length: Int) throws -> [UInt8] {
    try [UInt8](unsafeUninitializedCapacity: length) { buffer, count in
      count = Socket.read(file.rawValue, buffer.baseAddress, length)
      guard count > 0 else {
        if errno == EWOULDBLOCK {
          throw SocketError.blocked
        } else if errno == EBADF || count == 0 {
          throw SocketError.disconnected
        } else {
          throw SocketError.actionFailed("read")
        }
      }
    }
  }

  public func write(_ data: Data) throws -> Data.Index {
    return try data.withUnsafeBytes { buffer in
      let sent = Socket.write(file.rawValue, buffer.baseAddress! - data.startIndex, data.endIndex)
      guard sent > 0 else {
        if errno == EWOULDBLOCK {
          throw SocketError.blocked
        } else if errno == EBADF {
          throw SocketError.disconnected
        } else {
          throw SocketError.actionFailed("write")
        }
      }
      return sent
    }
  }

  // MARK: Closing

  public func close() throws {
    if Socket.close(file.rawValue) == -1 {
      throw SocketError.actionFailed("close")
    }
  }

  static func unsafeCast<A, B>(_ value: A) -> B {
    var value = value
    return withUnsafePointer(to: &value) { pointer in
      return pointer.withMemoryRebound(to: B.self, capacity: 1) { pointer in
        return pointer.pointee
      }
    }
  }
}
