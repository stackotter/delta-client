#if canImport(WinSDK)
import WinSDK.WinSock2
#endif
import Foundation

/// A socket that can connect to internet and Unix sockets.
///
/// It's basically just a low-overhead wrapper around the traditional C APIs for working with
/// sockets. The aim of the wrapper is to be type-safe and cross-platform.
public struct Socket: Sendable, Hashable {
  /// A type of socket that can be created.
  public enum SocketType {
    case tcp
    case udp
  }

  /// An address family that can be connected to.
  public enum AddressFamily {
    case ip4
    case ip6
    case unix
  }

  /// An ipv4, ipv6 or unix address.
  public enum Address: Hashable {
    case ip4(String, UInt16)
    case ip6(String, UInt16)
    case unix(String)

    /// An internal API for creating address from the C ``sockaddr_storage`` type.
    /// - Throws: An error is thrown if an invalid IP address is encountered or the address family
    ///   is unsupported.
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

    /// An internal API for converting addresses to their native storage type.
    /// - Throws: An error is thrown if an invalid IP address is encountered.
    func toNative() throws -> sockaddr {
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

    /// The size of the native type that this address is represented by.
    var nativeSize: Int {
      switch self {
        case .ip4: return MemoryLayout<sockaddr_in>.size
        case .ip6: return MemoryLayout<sockaddr_in6>.size
        case .unix: return MemoryLayout<sockaddr_un>.size
      }
    }
  }

  /// A set of socket flags.
  public struct Flags: OptionSet {
    public var rawValue: Int32

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }

    public static let nonBlocking = Flags(rawValue: O_NONBLOCK)
  }

  /// A file descriptor used as a reference to a particular socket.
  public struct FileDescriptor: RawRepresentable, Sendable, Hashable {
    public let rawValue: Socket.FileDescriptorType

    public init(rawValue: Socket.FileDescriptorType) {
      self.rawValue = rawValue
    }
  }

  // MARK: Properties

  /// The file descriptor of the socket.
  private let file: FileDescriptor

  // MARK: Init

  /// Creates a new socket.
  /// - Parameters:
  ///   - addressFamily: The address family that will be used.
  ///   - type: The type of socket to create.
  /// - Throws: An error is thrown if the socket could not be created.
  public init(_ addressFamily: AddressFamily, _ type: SocketType) throws {
    let descriptor = FileDescriptor(rawValue: Socket.socket(addressFamily.rawValue, type.rawValue, 0))
    guard descriptor != .invalid else {
      throw SocketError.actionFailed("create")
    }
    self.file = descriptor
  }

  // MARK: Flags

  /// Gets the socket's flags.
  /// - Throws: An error is thrown if ``fcntl`` fails.
  public func getFlags() throws -> Flags {
    let flags = Socket.fcntl(file.rawValue, F_GETFL)
    if flags == -1 {
      throw SocketError.actionFailed("get flags")
    }
    return Flags(rawValue: flags)
  }

  /// Sets the socket's flags.
  /// - Throws: An error is thrown if ``fcntl`` fails.
  public func setFlags(_ flags: Flags) throws {
    if Socket.fcntl(file.rawValue, F_SETFL, flags.rawValue) == -1 {
      throw SocketError.actionFailed("set flags")
    }
  }

  // MARK: Options

  /// Sets a socket option's value.
  public func setValue<O: SettableSocketOption>(_ value: O.Value, for option: O) throws {
    var value = option.makeSocketValue(from: value)
    let length = socklen_t(MemoryLayout<O.SocketValue>.size)
    guard Socket.setsockopt(file.rawValue, option.level, option.name, &value, length) >= 0 else {
      throw SocketError.actionFailed("set option")
    }
  }

  /// Gets a socket option's value.
  public func getValue<O: GettableSocketOption>(for option: O) throws -> O.Value {
    let valuePtr = UnsafeMutablePointer<O.SocketValue>.allocate(capacity: 1)
    var length = socklen_t(MemoryLayout<O.SocketValue>.size)
    guard Socket.getsockopt(file.rawValue, option.level, option.name, valuePtr, &length) >= 0 else {
      throw SocketError.actionFailed("get option")
    }
    return option.makeValue(from: valuePtr.pointee)
  }

  // MARK: Listening

  /// Binds the socket to a specific address.
  public func bind(to address: Address) throws {
    var addr = try address.toNative()
    let result = Socket.bind(file.rawValue, &addr, socklen_t(address.nativeSize))
    guard result >= 0 else {
      throw SocketError.actionFailed("bind")
    }
  }

  /// Attempts to start listening on the socket.
  public func listen(maxPendingConnection: Int32 = SOMAXCONN) throws {
    if Socket.listen(file.rawValue, maxPendingConnection) == -1 {
      let error = SocketError.actionFailed("listen")
      try close()
      throw error
    }
  }

  /// Attempts to accept a connection.
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

  /// Gets the address of the address that the socket is connected to.
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

  /// Gets the address of the socket.
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

  /// An internal method for creating ``in_addr`` from an IP address string.
  static func makeInAddr(fromIP4 address: String) throws -> in_addr {
    var addr = in_addr()
    guard address.withCString({ Socket.inet_pton(AF_INET, $0, &addr) }) == 1 else {
      throw SocketError.actionFailed("convert ipv4 address to in_addr (pton, address: '\(address)')")
    }
    return addr
  }

  /// An internal method for creating ``in6_addr`` from an IP address string.
  static func makeInAddr(fromIP6 address: String) throws -> in6_addr {
    var addr = in6_addr()
    guard address.withCString({ Socket.inet_pton(AF_INET6, $0, &addr) }) == 1 else {
      throw SocketError.actionFailed("convert ipv6 address to in6_addr (pton)")
    }
    return addr
  }

  // MARK: Connecting

  /// Attempts to connect to a given address.
  public func connect(to address: Address) throws {
    var addr = try address.toNative()
    let result = Socket.connect(file.rawValue, &addr, socklen_t(address.nativeSize))
    guard result >= 0 || errno == EISCONN else {
      if errno == EINPROGRESS {
        throw SocketError.blocked
      } else {
        throw SocketError.actionFailed("connect")
      }
    }
  }

  // MARK: IO

  /// Attempts to receive data from the socket and returns both the data and the address of the
  /// peer that sent the data.
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

  /// Attempts to read at most the given number of bytes from the socket.
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

  /// Attempts to write the given data to the socket.
  /// - Returns: The number of bytes sent.
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

  /// Attempts to close the socket gracefully.
  public func close() throws {
    if Socket.close(file.rawValue) == -1 {
      throw SocketError.actionFailed("close")
    }
  }

  /// An internal helper to clean up some of the ugly pointer code for operating with C types. Use
  /// with care.
  static func unsafeCast<A, B>(_ value: A) -> B {
    var value = value
    return withUnsafePointer(to: &value) { pointer in
      return pointer.withMemoryRebound(to: B.self, capacity: 1) { pointer in
        let val = pointer.pointee
        var x = val
        return val
      }
    }
  }
}
