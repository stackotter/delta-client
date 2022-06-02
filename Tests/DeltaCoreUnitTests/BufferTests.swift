import XCTest
import Foundation

@testable import struct DeltaCore.Buffer

final class BufferTests: XCTestCase {
  func testValidInput() throws {
    let input: [UInt8] = [
      0x80, // -128 (signed byte)
      0x80, // 128 (unsigned byte)
      1, 2, // 0x0102 (big endian unsigned short)
      1, 2, // 0x0201 (little endian unsigned short)
      0x80, 0x01, // -32767 (big endian signed short)
      0x80, 0x01, // 0x0180 (little endian signed short)
      1, 2, 3, 4, // 0x01020304 (big endian unsigned int)
      1, 2, 3, 0x80, // -2147286527 (little endian signed int)
      1, 2, 3, 4, 5, 6, 7, 8, // 0x0102030405060708 (big endian signed long)
      0xff, 0xff, 0xff, 0xff, 0x0f, // -1 (varint)
      0x81, 0x82, 0x84, 0x88, 0x90, 0xa0, 0xc0, 0x80, 0x01, // 0x0101010101010101 (varlong)
      0x00, 0xff, 0x00, 0xff, // 2.34184089e-38 (big endian float)
      0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0xff, 0x00, // 7.0641714803000305e-304 (little endian double)
      0x41, 0x61, 0x41, 0x61 // aAaA (string)
    ]

    var buffer = Buffer(input)

    XCTAssertEqual(try buffer.readSignedByte(), -128)
    XCTAssertEqual(try buffer.readByte(), 128)
    XCTAssertEqual(try buffer.readShort(endianness: .big), 0x0102)
    XCTAssertEqual(try buffer.readShort(endianness: .little), 0x0201)
    XCTAssertEqual(try buffer.readSignedShort(endianness: .big), -32767)
    XCTAssertEqual(try buffer.readSignedShort(endianness: .little), 0x0180)
    XCTAssertEqual(try buffer.readInteger(endianness: .big), 0x01020304)
    XCTAssertEqual(try buffer.readSignedInteger(endianness: .little), -2147286527)
    XCTAssertEqual(try buffer.readSignedLong(endianness: .big), 0x0102030405060708)
    XCTAssertEqual(try buffer.readVariableLengthInteger(), -1)
    XCTAssertEqual(try buffer.readVariableLengthLong(), 0x0101010101010101)
    XCTAssertEqual(try buffer.readFloat(endianness: .big), 2.34184089e-38)
    XCTAssertEqual(try buffer.readDouble(endianness: .big), 1.157756680498041e-279)
    XCTAssertEqual(try buffer.readString(length: 4), "AaAa")
    XCTAssertEqual(buffer.remaining, 0)
  }

  func testInvalidInput() throws {
    let testCases: [(String, [UInt8], (inout Buffer) throws -> Any)] = [
      (
        "insufficient bytes",
        [1],
        { buffer in try buffer.readShort(endianness: .big) }
      ),
      (
        "oversize varint",
        [0xff, 0xff, 0xff, 0xff, 0x1f], // One bit over the maximum
        { buffer in try buffer.readVariableLengthInteger() }
      ),
      (
        "oversize varlong",
        [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x71], // One bit of the maximum
        { buffer in try buffer.readVariableLengthLong() }
      )
    ]

    for (name, bytes, function) in testCases {
      do {
        var buffer = Buffer(bytes)
        _ = try function(&buffer)
        XCTFail("Invalid input (\(name)) didn't throw an error")
      } catch {
        continue
      }
    }
  }
}
