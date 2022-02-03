import SwiftUI
import DeltaCore

struct ServerListItem: View {
  @StateObject var pinger: Pinger
  
  var indicatorColor: SwiftUI.Color {
    let color: SwiftUI.Color
    if let result = pinger.response {
      switch result {
        case let .success(response):
          // Ping succeeded
          let isCompatible = response.version.protocolVersion == Constants.protocolVersion
          color = isCompatible ? .green : .yellow
        case .failure:
          // Connection failed
          color = .red
      }
    } else {
      // In the process of pinging
      color = .red
    }
    return color
  }
  
  var body: some View {
    HStack {
      Text(pinger.descriptor.name)
      Spacer()
      PingIndicator(color: indicatorColor)
    }
  }
}
