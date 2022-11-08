#if canImport(WinSDK)
import WinSDK.WinSock2
#endif
import Foundation

/// A socket option that is settable.
public protocol SettableSocketOption {
  /// The Swift type of the value.
  associatedtype Value
  /// The C type of the value.
  associatedtype SocketValue

  /// The 'name' of the option (in C).
  var name: Int32 { get }
  /// The 'level' of the option (in C).
  var level: Int32 { get }

  /// Converts a Swift value to a C value.
  func makeSocketValue(from value: Value) -> SocketValue
}

/// A socket option that is gettable.
public protocol GettableSocketOption {
  /// The Swift type of the value.
  associatedtype Value
  /// The C type of the value.
  associatedtype SocketValue

  /// The 'name' of the option (in C).
  var name: Int32 { get }
  /// The 'level' of the option (in C).
  var level: Int32 { get }

  /// Converts a C value to a Swift value.
  func makeValue(from socketValue: SocketValue) -> Value
}

/// A socket option that is both settable and gettable.
public protocol SocketOption: SettableSocketOption, GettableSocketOption {
  /// The Swift type of the value.
  associatedtype Value
  /// The C type of the value.
  associatedtype SocketValue

  /// The 'name' of the option (in C).
  var name: Int32 { get }
  /// The 'level' of the option (in C).
  var level: Int32 { get }

  /// Converts a Swift value to a C value.
  func makeValue(from socketValue: SocketValue) -> Value
  /// Converts a C value to a Swift value.
  func makeSocketValue(from value: Value) -> SocketValue
}

extension SettableSocketOption {
  public var level: Int32 {
    return SOL_SOCKET
  }
}

extension GettableSocketOption {
  public var level: Int32 {
    return SOL_SOCKET
  }
}

extension SocketOption {
  public var level: Int32 {
    return SOL_SOCKET
  }
}

// MARK: Value types

/// The value of a membership request socket option.
public struct MembershipRequest {
  var groupAddress: in_addr
  var localAddress: in_addr

  /// Creates a new membership request.
  public init(groupAddress: String, localAddress: String) throws {
    self.groupAddress = try Socket.makeInAddr(fromIP4: groupAddress)
    self.localAddress = try Socket.makeInAddr(fromIP4: localAddress)
  }
}

/// The value of a time socket option (e.g. timeouts).
public struct TimeValue {
  /// The number of seconds.
  public var seconds: Int
  /// The number of micro seconds (used to add precision).
  public var microSeconds: Int

  /// Creates a new time value.
  public init(seconds: Int = 0, microSeconds: Int = 0) {
    self.seconds = seconds
    self.microSeconds = microSeconds
  }
}

// MARK: Option types

/// A boolean socket option (e.g. allow local address reuse).
public struct BoolSocketOption: SocketOption {
  public var name: Int32

  public init(name: Int32) {
    self.name = name
  }

  public func makeValue(from socketValue: Int32) -> Bool {
    socketValue > 0
  }

  public func makeSocketValue(from value: Bool) -> Int32 {
    value ? 1 : 0
  }
}

/// A membership request socket option.
public struct MembershipRequestSocketOption: SettableSocketOption {
  public var name: Int32

  public init(name: Int32) {
    self.name = name
  }

  public var level: Int32 {
    Int32(IPPROTO_IP)
  }

  public func makeSocketValue(from value: MembershipRequest) -> MembershipRequest {
    value
  }
}

/// A generic type for creating simple socket options where the Swift and C types of the value are the same.
public struct SimpleSocketOption<T>: SocketOption {
  public var name: Int32

  public init(name: Int32) {
    self.name = name
  }

  public func makeValue(from socketValue: T) -> T {
    socketValue
  }

  public func makeSocketValue(from value: T) -> T {
    value
  }
}

/// An integer socket option.
public typealias Int32SocketOption = SimpleSocketOption<Int32>
/// A time socket option (e.g. a timeout).
public typealias TimeSocketOption = SimpleSocketOption<TimeValue>

// MARK: Common options

public extension BoolSocketOption {
  /// Whether local address reuse is allowed or not.
  static var localAddressReuse: Self {
    BoolSocketOption(name: SO_REUSEADDR)
  }
}

public extension MembershipRequestSocketOption {
  /// A request to add the socket to a multicast group.
  static var addMembership: Self {
    MembershipRequestSocketOption(name: IP_ADD_MEMBERSHIP)
  }

  /// A request to remove the socket from a multicast group.
  static var dropMembership: Self {
    MembershipRequestSocketOption(name: IP_DROP_MEMBERSHIP)
  }
}

public extension Int32SocketOption {
  /// The size of the send buffer.
  static var sendBufferSize: Self {
    Int32SocketOption(name: SO_SNDBUF)
  }

  /// The size of the receive buffer.
  static var receiveBufferSize: Self {
    Int32SocketOption(name: SO_RCVBUF)
  }
}

public extension TimeSocketOption {
  /// The timeout for receiving data.
  static var receiveTimeout: Self {
    TimeSocketOption(name: SO_RCVTIMEO)
  }

  /// The timeout for sending data.
  static var sendTimeout: Self {
    TimeSocketOption(name: SO_SNDTIMEO)
  }
}
