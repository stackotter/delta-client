//
//  ServerPingerDetailView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

struct ServerPingerDetailView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @ObservedObject var pinger: ServerPinger
  
  var body: some View {
    let descriptor = pinger.descriptor
    VStack(alignment: .leading) {
      Text(descriptor.name)
        .font(.title)
      Text("\(descriptor.host):\(String(descriptor.port))")
      if let pingInfo = pinger.pingResult {
        Text("\(pingInfo.numPlayers)/\(pingInfo.maxPlayers) online")
          .padding(.bottom, 8)
        Text(pingInfo.description)
      } else {
        Text("Pinging..")
      }
      
      Button("Play") {
        appState.update(to: .playServer(descriptor))
      }
    }
  }
}
