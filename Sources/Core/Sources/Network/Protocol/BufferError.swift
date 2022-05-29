import Foundation

/// An error thrown by ``Buffer``.
public enum BufferError: Error {
  case invalidByteInUTF8String
  case skippedOutOfBounds(length: Int, index: Int)
  case outOfBounds(length: Int, index: Int)
  case rangeOutOfBounds(length: Int, start: Int, end: Int)
  case variableIntegerTooLarge(maximum: Int)
}
