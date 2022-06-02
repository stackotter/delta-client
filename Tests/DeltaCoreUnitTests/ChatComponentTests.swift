import XCTest
import Foundation

@testable import struct DeltaCore.ChatComponent

final class ChatComponentTests: XCTestCase {
  func testValidJSON() throws {
    let testCases: [(String, ChatComponent)] = [
      (
        #"{"italic":false,"extra":[{"color":"yellow","clickEvent":{"action":"open_url","value":"http://www.hypixel.ne"},"text":"www.hypixel.ne"}],"text":""}"#,
        ChatComponent(
          style: .init(italic: false),
          content: .string(""),
          children: [
            ChatComponent(
              style: .init(color: .yellow),
              content: .string("www.hypixel.ne")
            )
          ]
        )
      ),
      (
        // swiftlint:disable:next line_length
        #"{"italic":false,"extra":[{"color":"white","text":" "},{"color":"dark_gray","text":"["},{"color":"aqua","text":"■"},{"color":"gray","text":"■■■■■■■"}],"text":""}"#,
        ChatComponent(
          style: .init(italic: false),
          content: .string(""),
          children: [
            ChatComponent(
              style: .init(color: .white),
              content: .string(" ")
            ),
            ChatComponent(
              style: .init(color: .darkGray),
              content: .string("[")
            ),
            ChatComponent(
              style: .init(color: .aqua),
              content: .string("■")
            ),
            ChatComponent(
              style: .init(color: .gray),
              content: .string("■■■■■■■")
            )
          ]
        )
      )
    ]

    for (json, expected) in testCases {
      let data = json.data(using: .utf8)!
      let parsed = try JSONDecoder().decode(ChatComponent.self, from: data)
      XCTAssertEqual(
        parsed,
        expected
      )
    }
  }
}
