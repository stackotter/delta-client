//
//  ServerDetailView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct ServerDetailView: View {
  var viewState: ViewState<AppViewState>
  @ObservedObject var pinger: ServerPinger
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading) {
        Text(pinger.descriptor.name)
          .font(.title)
          .bold()
        Text("\(pinger.descriptor.host):\(String(pinger.descriptor.port))")
          .font(.title2)
      }
      
      if let pingResult = pinger.pingResult {
        VStack(alignment: .leading) {
          Text("\(pingResult.numPlayers)/\(pingResult.maxPlayers) players")
          Text("version: \(pingResult.versionName)")
        }
        
        if (pingResult.protocolVersion != PROTOCOL_VERSION) {
          VStack(alignment: .center)  {
            Text("unsupported protocol version")
          }
        }
        
        HStack {
          Button("play commands") {
            viewState.update(to: .playing(withRendering: false, serverDescriptor: pinger.descriptor))
          }
          Button("play render") {
            viewState.update(to: .playing(withRendering: true, serverDescriptor: pinger.descriptor))
          }
        }
      } else {
        Text("pinging..")
      }
    }
    .frame(width: 200)
  }
}
