import SwiftUI
import DeltaCore

struct ServerDetail: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @ObservedObject var pinger: Pinger
  
  var body: some View {
    let descriptor = pinger.descriptor
    VStack(alignment: .leading) {
      Text(descriptor.name)
        .font(.title)
      Text(descriptor.description)
        .padding(.bottom, 8)
      
      if let result = pinger.response {
        switch result {
          case let .success(response):
            Text("\(response.description.text)")
              .padding(.bottom, 8)
            
            Text(verbatim: "\(response.players.online)/\(response.players.max) online")
            MCAttributedText(
              string: "Version: \(response.version.name) \(response.version.protocolVersion == Constants.protocolVersion ? "" : "(incompatible)")",
              alignment: .left
            )
              .padding(.bottom, 8)
            
            Button("Play") {
              appState.update(to: .playServer(descriptor))
            }
              .buttonStyle(PrimaryButtonStyle())
              .frame(width: 150)
          case let .failure(error):
            Text("Connection failed: \(error.localizedDescription)")
              .padding(.bottom, 8)
            Button("Play") { }
              .buttonStyle(DisabledButtonStyle())
              .frame(width: 150)
              .disabled(true)
        }
      } else {
        Text("Pinging..")
          .padding(.bottom, 8)
        Button("Play") { }
          .buttonStyle(DisabledButtonStyle())
          .frame(width: 150)
          .disabled(true)
      }
    }
  }
}
