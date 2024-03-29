import XCTest
import Foundation

@testable import struct DeltaCore.LegacyFormattedText

private typealias Token = LegacyFormattedText.Token

final class LegacyFormattedTextTests: XCTestCase {
  func testValidText() throws {
    let testCases: [(String, [Token])] = [
      ("§cX§nY", [
        Token(string: "X", color: .red, style: nil),
        Token(string: "Y", color: .red, style: .underline)
      ]),
      ("§nX§cY", [
        Token(string: "X", color: nil, style: .underline),
        Token(string: "Y", color: .red, style: nil)
      ]),
      ("first§csecond§a§lthird", [
        Token(string: "first", color: nil, style: nil),
        Token(string: "second", color: .red, style: nil),
        Token(string: "third", color: .green, style: .bold)
      ])
    ]

    for (input, expectedTokens) in testCases {
      XCTAssertEqual(
        LegacyFormattedText(input).tokens,
        expectedTokens,
        "Failed to parse '\(input)'"
      )
    }
  }
}
