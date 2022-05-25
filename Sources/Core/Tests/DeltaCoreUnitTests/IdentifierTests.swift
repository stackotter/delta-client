import XCTest
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
      "%"
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
}
