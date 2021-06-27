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
  
  var body: some View {
    let isOnline = pinger.pingResult != nil
    let isCompatible = pinger.pingResult?.protocolVersion == Constants.protocolVersion
    let indicatorColor: Color = isOnline ? (isCompatible ? .green : .yellow) : .red
    HStack {
      Text(pinger.descriptor.name)
      Spacer()
      Circle()
        .foregroundColor(indicatorColor)
        .fixedSize()
    }
  }
}
