import Foundation

public enum Either<Left, Right> {
  case left(Left)
  case right(Right)
}

extension Either: Decodable where Left: Decodable, Right: Decodable {
  public init(from decoder: Decoder) throws {
    do {
      self = .left(try Left(from: decoder))
    } catch {
      self = .right(try Right(from: decoder))
    }
  }
}

extension Either: Encodable where Left: Encodable, Right: Encodable {
  public func encode(to encoder: Encoder) throws {
    switch self {
      case let .left(value):
        try value.encode(to: encoder)
      case let .right(value):
        try value.encode(to: encoder)
    }
  }
}
