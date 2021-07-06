//
//  ServerPingerListItem.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

struct ServerPingerListItem: View {
  @StateObject var pinger: Pinger
  
  var indicatorColor: Color {
    let color: Color
    if let result = pinger.pingResult {
      switch result {
        case let .success(info):
          // Ping succeeded
          let isCompatible = info.protocolVersion == Constants.protocolVersion
          color = isCompatible ? .green : .yellow
        case .failure:
          // Connection failed
          color = .red
      }
    } else {
      // In the process of pinging
      color = .red
    }
    return color
  }
  
  var body: some View {
    HStack {
      Text(pinger.descriptor.name)
      Spacer()
      PingIndicator(color: indicatorColor)
    }
  }
}
