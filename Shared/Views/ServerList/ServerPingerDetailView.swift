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
  @ObservedObject var pinger: Pinger
  
  var body: some View {
    let descriptor = pinger.descriptor
    VStack(alignment: .leading) {
      Text(descriptor.name)
        .font(.title)
      Text(descriptor.description)
      
      if let result = pinger.pingResult {
        switch result {
          case let .success(info):
            Text("\(info.numPlayers)/\(info.maxPlayers) online")
              .padding(.bottom, 8)
            Text(info.description)
          case let .failure(error):
            Text("Connection failed: \(error.localizedDescription)")
        }
      } else {
        Text("Pinging..")
      }
      
      Button("Play") {
        appState.update(to: .playServer(descriptor))
      }
    }
  }
}
