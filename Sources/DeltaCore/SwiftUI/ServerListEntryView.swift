//
//  ServerListEntryView.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 13/12/20.
//

import SwiftUI

struct ServerListEntryView: View {
  @ObservedObject var pinger: ServerPinger
  
  var body: some View {
    HStack {
      Text(pinger.descriptor.name)
      Spacer()
      Circle()
        .foregroundColor((pinger.pingResult == nil) ? .red : ((pinger.pingResult?.protocolVersion == Constants.protocolVersion) ? .green : .yellow))
        .fixedSize()
    }
  }
}
