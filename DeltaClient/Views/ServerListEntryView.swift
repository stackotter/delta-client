//
//  ServerListEntryView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 13/12/20.
//

import SwiftUI

struct ServerListEntryView: View {
  @ObservedObject var server: ServerPinger
  
  var body: some View {
    HStack {
      Text(server.descriptor.name)
      Spacer()
      Circle()
        .foregroundColor((server.pingInfo == nil) ? .red : ((server.pingInfo?.protocolVersion == PROTOCOL_VERSION) ? .green : .yellow))
        .fixedSize()
    }
  }
}
