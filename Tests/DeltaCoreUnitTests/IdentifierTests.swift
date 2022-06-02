import XCTest
import Foundation

@testable import struct DeltaCore.Identifier

final class IdentifierTests: XCTestCase {
  func testValidIdentifiers() throws {
    let namespaces = ["minecraft", "delta-client", "123delta_-client_"]
    let names = ["block/dirt.png", "dirt", "diamond_sword", "-/_123iron_sword"]
    
    for namespace in namespaces {
      for name in names {
        let identifier = "\(namespace):\(name)"
        let parsed = try Identifier(identifier)
        XCTAssertEqual(
          parsed,
          Identifier(namespace: namespace, name: name),
          "Expected '\(identifier)' to be parsed correctly. Got '\(parsed.namespace):\(parsed.name)'"
        )
      }
    }

    for name in names {
      let parsed = try Identifier(name)
      XCTAssertEqual(
        parsed,
        Identifier(namespace: "minecraft", name: name),
        "Expected '\(name)' to be parsed correctly. Got '\(parsed.namespace):\(parsed.name)'"
      )
    }
  }

  func testInvalidIdentifiers() throws {
    let identifiers = [
      "minecraft:block:dirt",
      "block:",
      "minecraft:diamond$sword",
      "%",
      ":iron_shovel"
    ]

    for identifier in identifiers {
      do {
        let parsed = try Identifier(identifier)
        XCTFail("Expected parsing '\(identifier)' to throw an error. Got '\(parsed.name):\(parsed.name)'")
      } catch {
        continue
      }
    }
  }

  func testDecoding() throws {
    struct Payload: Codable {
      let identifierString: Identifier
      let identifierParts: Identifier
    }

    let namespace = "minecraft"
    let name = "block/dirt.png"
    let identifier = Identifier(namespace: namespace, name: name)

    let json = """
{
  "identifierString": "\(namespace):\(name)",
  "identifierParts": ["\(namespace)", "\(name)"]
}
""".data(using: .utf8)!
    
    let decoded = try JSONDecoder().decode(Payload.self, from: json)

    XCTAssertEqual(
      decoded.identifierString,
      identifier,
      "Failed to decode identifier '\(identifier)' encoded as a JSON string. Got '\(decoded.identifierString)'"
    )

    XCTAssertEqual(
      decoded.identifierParts,
      identifier,
      "Failed to decode identifier '\(identifier)' encoded as a JSON array. Got '\(decoded.identifierParts)'"
    )
  }

  func testEncoding() throws {
    let namespace = "minecraft"
    let name = "block/dirt.png"
    let identifier = Identifier(namespace: namespace, name: name)

    let json = String(data: try JSONEncoder().encode(identifier), encoding: .utf8)!
    
    let expected = "[\"\(namespace)\",\"\(name.replacingOccurrences(of: "/", with: "\\/"))\"]"
    XCTAssertEqual(
      json,
      expected,
      "Incorrectly encoded identifier '\(identifier)'. Expected '\(expected)'. Got '\(json)'"
    )
  }
}
