//
//  ServerDetailView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct ServerDetailView: View {
  @ObservedObject var viewState: ViewState<AppViewStateEnum>
  @ObservedObject var server: ServerPinger
  
  var body: some View {
    Spacer()
    
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading) {
        Text(server.descriptor.name)
          .font(.title)
          .bold()
        Text("\(server.descriptor.host):\(String(server.descriptor.port))")
          .font(.title2)
      }
      
      VStack(alignment: .leading) {
        if (server.pingInfo != nil) {
          let pingInfo = server.pingInfo!
          Text("\(pingInfo.numPlayers)/\(pingInfo.maxPlayers) players")
          Text("version: \(pingInfo.versionName)")
        } else {
          Text("Pinging..")
        }
      }
      
      HStack {
        Button(action: {
          viewState.update(to: .playing(withRendering: false, serverDescriptor: server.descriptor))
        }) {
          Text("Play Commands")
        }
        
        Button(action: {
          viewState.update(to: .playing(withRendering: true, serverDescriptor: server.descriptor))
        }) {
          Text("Play Render")
        }
      }
    }
    
    if (server.pingInfo?.protocolVersion != PROTOCOL_VERSION) {
      VStack(alignment: .center)  {
        Text("warning: this server uses a different protocol to this client version")
      }
    }
    
    Spacer()
  }
}
