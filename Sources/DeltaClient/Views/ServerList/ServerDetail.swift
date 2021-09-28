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
      
      if let result = pinger.pingResult {
        switch result {
          case let .success(info):
            Text(verbatim: "\(info.numPlayers)/\(info.maxPlayers) online")
            Text("version: \(info.versionName) \(info.protocolVersion == Constants.protocolVersion ? "" : "(incompatible)")")
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
              .buttonStyle(PrimaryButtonStyle())
              .frame(width: 150)
              .disabled(false)
        }
      } else {
        Text("Pinging..")
          .padding(.bottom, 8)
        Button("Play") { }
          .buttonStyle(DisabledButtonStyle())
          .frame(width: 150)
      }
    }
  }
}
