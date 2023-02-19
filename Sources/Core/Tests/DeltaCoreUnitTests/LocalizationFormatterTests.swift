import XCTest
import Foundation

@testable import struct DeltaCore.LocalizationFormatter

final class LocalizationFormatterTests: XCTestCase {
  func testValidInputs() throws {
    let inputs: [(String, [String], String)] = [
      ("%s, world!", ["Hello"], "Hello, world!"),
      (
        "%s, %s, %1$s again, %s, %2$s again, %3$s, %1$s again, %1$s%2$s%3$s",
        ["1", "2", "3"],
        "1, 2, 1 again, 3, 2 again, 3, 1 again, 123"
      ),
      ("%% %%s %%%s %%%%s %%%%%s", ["1", "2"], "% %s %1 %%s %%2")
    ]

    for (template, substitutions, expected) in inputs {
      XCTAssertEqual(
        LocalizationFormatter.format(template, withSubstitutions: substitutions),
        expected
      )
    }
  }

  func testInvalidInputs() throws {
    let inputs: [(String, [String], String)] = [
      ("%", ["Hi"], "%"),
      ("% s", ["Hi"], "% s"),
      ("%s %$s", ["Hi", "Hello"], "Hi %$s"),
      ("%s %s %1$s %2$s", ["Hi"], "Hi %s Hi %2$s"),
      ("%$1s", ["Hi"], "%$1s"),
    ]

    for (template, substitutions, expected) in inputs {
      XCTAssertEqual(
        LocalizationFormatter.format(template, withSubstitutions: substitutions),
        expected
      )
    }
  }
}
