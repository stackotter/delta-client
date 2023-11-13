import SwiftUI
import Combine

struct AddressField: View {
  // swiftlint:disable:next force_try
  static private let ipRegex = try! NSRegularExpression(
    pattern: "^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)(\\.(?!$)|$)){4}$"
  )

  // swiftlint:disable:next force_try
  static private let domainRegex = try! NSRegularExpression(
    pattern: "^[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*$"
  )

  let title: String

  @State private var string: String
  @Binding private var host: String
  @Binding private var port: UInt16?

  @Binding private var isValid: Bool

  init(_ title: String, host: Binding<String>, port: Binding<UInt16?>, isValid: Binding<Bool>) {
    self.title = title
    _host = host
    _port = port

    if let port = port.wrappedValue {
      _string = State(initialValue: "\(host.wrappedValue):\(port)")
    } else {
      _string = State(initialValue: host.wrappedValue)
    }

    _isValid = isValid
  }

  private func update(_ newValue: String) {
    let components = newValue.split(separator: ":")
    if components.count == 0 {
      log.trace("Invalid ip, empty string")
      isValid = false
    } else if components.count > 2 {
      log.trace("Invalid ip, too many components: '\(newValue)'")
      isValid = false
    } else if newValue.hasSuffix(":") {
      log.trace("Invalid ip, empty port: '\(newValue)'")
      isValid = false
    }

    // Check host component
    if components.count > 0 {
      let hostString = String(components[0])
      let range = NSRange(location: 0, length: hostString.utf16.count)
      let isIp = Self.ipRegex.firstMatch(in: hostString, options: [], range: range) != nil
      let isDomain = Self.domainRegex.firstMatch(in: hostString, options: [], range: range) != nil
      if isIp || isDomain {
        host = hostString
        isValid = true
      } else {
        log.trace("Invalid host component: '\(hostString)'")
        isValid = false
      }
    }

    // Check port component
    if components.count == 2 {
      let portString = components[1]
      if let port = UInt16(portString) {
        self.port = port
        isValid = true
      } else {
        log.trace("Invalid port component: '\(portString)'")
        isValid = false
      }
    } else {
      port = nil
    }
  }

  var body: some View {
    TextField(title, text: $string)
      .onReceive(Just(string), perform: update)
      .onAppear {
        update(string)
      }
  }
}
