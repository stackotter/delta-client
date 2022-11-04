#if canImport(Glibc)
import Glibc

public extension Socket {
    typealias FileDescriptorType = Int32
}

extension Socket.FileDescriptor {
    static let invalid = Socket.FileDescriptor(rawValue: -1)
}

extension Socket.SocketType {
  public var rawValue: Int32 {
    switch self {
      case .tcp: return Int32(SOCK_STREAM)
      case .udp: return Int32(SOCK_DGRAM)
    }
  }
}

extension Socket.AddressFamily {
  public var rawValue: Int32 {
    switch self {
      case .ip4: return Int32(AF_INET)
      case .ip6: return Int32(AF_INET6)
      case .unix: return Int32(AF_UNIX)
    }
  }
}

extension Socket {
    static let tcp = Int32(SOCK_STREAM)
    static let udp = Int32(SOCK_DGRAM)

    static let in_addr_any = Glibc.in_addr(s_addr: Glibc.in_addr_t(0))

    static func makeAddressINET(port: UInt16) -> Glibc.sockaddr_in {
        Glibc.sockaddr_in(
            sin_family: sa_family_t(AF_INET),
            sin_port: port.bigEndian,
            sin_addr: in_addr_any,
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
        )
    }

    static func makeAddressINET6(port: UInt16) -> Glibc.sockaddr_in6 {
        Glibc.sockaddr_in6(
            sin6_family: sa_family_t(AF_INET6),
            sin6_port: port.bigEndian,
            sin6_flowinfo: 0,
            sin6_addr: in6addr_any,
            sin6_scope_id: 0
        )
    }

    static func makeAddressLoopback(port: UInt16) -> Glibc.sockaddr_in6 {
        Glibc.sockaddr_in6(
            sin6_family: sa_family_t(AF_INET6),
            sin6_port: port.bigEndian,
            sin6_flowinfo: 0,
            sin6_addr: in6addr_loopback,
            sin6_scope_id: 0
        )
    }

    static func makeAddressUnix(path: String) -> Glibc.sockaddr_un {
        var addr = Glibc.sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathCount = min(path.utf8.count, 104)
        let len = UInt8(MemoryLayout<UInt8>.size + MemoryLayout<sa_family_t>.size + pathCount + 1)
        _ = withUnsafeMutablePointer(to: &addr.sun_path.0) { ptr in
            path.withCString {
                strncpy(ptr, $0, Int(len))
            }
        }
        return addr
    }

    static func socket(_ domain: Int32, _ type: Int32, _ protocol: Int32) -> Int32 {
        Glibc.socket(domain, type, `protocol`)
    }

    static func fcntl(_ fd: Int32, _ cmd: Int32) -> Int32 {
        Glibc.fcntl(fd, cmd)
    }

    static func fcntl(_ fd: Int32, _ cmd: Int32, _ value: Int32) -> Int32 {
        Glibc.fcntl(fd, cmd, value)
    }

    static func setsockopt(_ fd: Int32, _ level: Int32, _ name: Int32,
                           _ value: UnsafeRawPointer!, _ len: socklen_t) -> Int32 {
        Glibc.setsockopt(fd, level, name, value, len)
    }

    static func getsockopt(_ fd: Int32, _ level: Int32, _ name: Int32,
                           _ value: UnsafeMutableRawPointer!, _ len: UnsafeMutablePointer<socklen_t>!) -> Int32 {
        Glibc.getsockopt(fd, level, name, value, len)
    }

    static func getpeername(_ fd: Int32, _ addr: UnsafeMutablePointer<sockaddr>!, _ len: UnsafeMutablePointer<socklen_t>!) -> Int32 {
        Glibc.getpeername(fd, addr, len)
    }

    static func getsockname(_ fd: Int32, _ addr: UnsafeMutablePointer<sockaddr>!, _ len: UnsafeMutablePointer<socklen_t>!) -> Int32 {
        Glibc.getsockname(fd, addr, len)
    }

    static func inet_ntop(_ domain: Int32, _ addr: UnsafeRawPointer!,
                          _ buffer: UnsafeMutablePointer<CChar>!, _ addrLen: socklen_t) throws {
        if Glibc.inet_ntop(domain, addr, buffer, addrLen) == nil {
            throw SocketError.makeFailed("inet_ntop")
        }
    }

    static func inet_pton(_ domain: Int32, _ buffer: UnsafePointer<CChar>!, _ addr: UnsafeMutableRawPointer!) -> Int32 {
        Glibc.inet_pton(domain, buffer, addr)
    }

    static func bind(_ fd: Int32, _ addr: UnsafePointer<sockaddr>!, _ len: socklen_t) -> Int32 {
        Glibc.bind(fd, addr, len)
    }

    static func listen(_ fd: Int32, _ backlog: Int32) -> Int32 {
        Glibc.listen(fd, backlog)
    }

    static func accept(_ fd: Int32, _ addr: UnsafeMutablePointer<sockaddr>!, _ len: UnsafeMutablePointer<socklen_t>!) -> Int32 {
        Glibc.accept(fd, addr, len)
    }

    static func connect(_ fd: Int32, _ addr: UnsafePointer<sockaddr>!, _ len: socklen_t) -> Int32 {
        Glibc.connect(fd, addr, len)
    }

    static func read(_ fd: Int32, _ buffer: UnsafeMutableRawPointer!, _ nbyte: Int) -> Int {
        Glibc.read(fd, buffer, nbyte)
    }

    static func write(_ fd: Int32, _ buffer: UnsafeRawPointer!, _ nbyte: Int) -> Int {
        Glibc.send(fd, buffer, nbyte, Int32(MSG_NOSIGNAL))
    }

    static func close(_ fd: Int32) -> Int32 {
        Glibc.close(fd)
    }

    static func unlink(_ addr: UnsafePointer<CChar>!) -> Int32 {
        Glibc.unlink(addr)
    }

    static func poll(_ fds: UnsafeMutablePointer<pollfd>!, _ nfds: UInt32, _ tmo_p: Int32) -> Int32 {
        Glibc.poll(fds, UInt(nfds), tmo_p)
    }

    static func pollfd(fd: FileDescriptorType, events: Int16, revents: Int16) -> Glibc.pollfd {
        Glibc.pollfd(fd: fd, events: events, revents: revents)
    }
}

#endif
