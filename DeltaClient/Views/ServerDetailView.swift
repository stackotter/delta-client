//
//  ServerDetailView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct ServerDetailView: View {
  @ObservedObject var viewState: ViewState<AppViewStateEnum>
  @ObservedObject var pinger: ServerPinger
  
  var body: some View {
    Spacer()
    
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading) {
        Text(pinger.descriptor.name)
          .font(.title)
          .bold()
        Text("\(pinger.descriptor.host):\(String(pinger.descriptor.port))")
          .font(.title2)
      }
      
      VStack(alignment: .leading) {
        if (pinger.pingResult != nil) {
          let pingResult = pinger.pingResult!
          Text("\(pingResult.numPlayers)/\(pingResult.maxPlayers) players")
          Text("version: \(pingResult.versionName)")
        } else {
          Text("Pinging..")
        }
      }
      
      HStack {
        Button(action: {
          viewState.update(to: .playing(withRendering: false, serverDescriptor: pinger.descriptor))
        }) {
          Text("Play Commands")
        }
        
        Button(action: {
          viewState.update(to: .playing(withRendering: true, serverDescriptor: pinger.descriptor))
        }) {
          Text("Play Render")
        }
      }
    }
    
    if (pinger.pingResult?.protocolVersion != PROTOCOL_VERSION) {
      VStack(alignment: .center)  {
        Text("warning: this server uses a different protocol to this client version")
      }
    }
    
    Spacer()
  }
}
