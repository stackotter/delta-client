import Foundation

// Protocol version numbers can be found at https://wiki.vg/Protocol_version_numbers

/// The enum containing all supported protocol versions.
public enum ProtocolVersion: Int {
  // The v in the version names is required because in swift, 1_16_1 is interpreted as the number 1161
  // Don't include the v for snapshot versions because it's not necessary and it's less obvious that
  // it's not part of the version's name because snapshot names include letters.
  case v1_16_1 = 736
}
