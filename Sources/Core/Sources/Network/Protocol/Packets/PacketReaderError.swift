import Foundation

/// An error thrown by ``PacketReader``.
public enum PacketReaderError: Error {
  case stringTooLong(length: Int)
  case invalidNBT(Error)
  case invalidIdentifier(String)
}
