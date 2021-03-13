//
//  ServerDetailView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct ServerDetailView: View {
  @ObservedObject var viewState: ViewState
  @ObservedObject var server: ServerPinger
  
  var body: some View {
    Spacer()
    
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading) {
        Text(server.info.name)
          .font(.title)
          .bold()
        Text("\(server.info.host):\(String(server.info.port))")
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
          viewState.playServer(withInfo: server.info, withRendering: false)
        }) {
          Text("Play Commands")
        }
        
        Button(action: {
          viewState.playServer(withInfo: server.info, withRendering: true)
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
