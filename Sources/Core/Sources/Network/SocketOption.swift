#if canImport(WinSDK)
import WinSDK.WinSock2
#endif
import Foundation

public protocol SettableSocketOption {
  associatedtype Value
  associatedtype SocketValue

  var name: Int32 { get }
  func getLevel() -> Int32
  func makeSocketValue(from value: Value) -> SocketValue
}

public protocol GettableSocketOption {
  associatedtype Value
  associatedtype SocketValue

  var name: Int32 { get }
  func getLevel() -> Int32
  func makeValue(from socketValue: SocketValue) -> Value
}

public protocol SocketOption: SettableSocketOption, GettableSocketOption {
  associatedtype Value
  associatedtype SocketValue

  var name: Int32 { get }
  func getLevel() -> Int32
  func makeValue(from socketValue: SocketValue) -> Value
  func makeSocketValue(from value: Value) -> SocketValue
}

extension SettableSocketOption {
  public func getLevel() -> Int32 {
    SOL_SOCKET
  }
}

extension GettableSocketOption {
  public func getLevel() -> Int32 {
    SOL_SOCKET
  }
}

extension SocketOption {
  public func getLevel() -> Int32 {
    SOL_SOCKET
  }
}

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

public struct MembershipRequest {
  var groupAddress: in_addr
  var localAddress: in_addr

  public init(groupAddress: String, localAddress: String) throws {
    self.groupAddress = try Socket.makeInAddr(fromIP4: groupAddress)
    self.localAddress = try Socket.makeInAddr(fromIP4: localAddress)
  }
}

public struct TimeValue {
  public var seconds: Int
  public var microSeconds: Int

  public init(seconds: Int = 0, microSeconds: Int = 0) {
    self.seconds = seconds
    self.microSeconds = microSeconds
  }
}

public typealias Int32SocketOption = SimpleSocketOption<Int32>
public typealias TimeSocketOption = SimpleSocketOption<TimeValue>

public struct MembershipRequestSocketOption: SettableSocketOption {
  public var name: Int32

  public init(name: Int32) {
    self.name = name
  }

  public func getLevel() -> Int32 {
    IPPROTO_IP
  }

  public func makeSocketValue(from value: MembershipRequest) -> MembershipRequest {
    value
  }
}

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

public extension SocketOption where Self == BoolSocketOption {
  static var localAddressReuse: Self {
    BoolSocketOption(name: SO_REUSEADDR)
  }
}

public extension SettableSocketOption where Self == MembershipRequestSocketOption {
  static var addMembership: Self {
    MembershipRequestSocketOption(name: IP_ADD_MEMBERSHIP)
  }

  static var dropMembership: Self {
    MembershipRequestSocketOption(name: IP_DROP_MEMBERSHIP)
  }
}

public extension SocketOption where Self == Int32SocketOption {
  static var sendBufferSize: Self {
    Int32SocketOption(name: SO_SNDBUF)
  }

  static var receiveBufferSize: Self {
    Int32SocketOption(name: SO_RCVBUF)
  }
}

public extension SocketOption where Self == TimeSocketOption {
  static var receiveTimeout: Self {
    TimeSocketOption(name: SO_RCVTIMEO)
  }

  static var sendTimeout: Self {
    TimeSocketOption(name: SO_SNDTIMEO)
  }
}
