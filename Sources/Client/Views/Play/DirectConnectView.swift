import SwiftUI
import DeltaCore

struct DirectConnectView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  @State var host: String = ""
  @State var port: UInt16? = nil
  
  @State var errorMessage: String? = nil
  @State var isAddressValid = false
  
  private func verify() -> Bool {
    if !isAddressValid {
      errorMessage = "Invalid IP"
    } else {
      return true
    }
    return false
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Direct connect")
        .font(Font.custom(.worksans, size: 25))
        .foregroundColor(.white)
      AddressField("Address", host: $host, port: $port, isValid: $isAddressValid)
      HStack {
        StyledButton(
          action: {
            if verify() {
              let descriptor = ServerDescriptor(name: "Direct Connect", host: host, port: port)
              appState.update(to: .playServer(descriptor))
            }
          },
          text: "Connect"
        )
          .frame(width: 120)
        Spacer()
        if let message = errorMessage {
          Text(message)
            .font(Font.custom(.worksans, size: 11))
            .foregroundColor(.red)
            .frame(maxWidth: 250)
        }
      }
    }
  }
}
