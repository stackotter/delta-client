//
//  ServerListEntryView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 13/12/20.
//

import SwiftUI

struct ServerListEntryView: View {
  @ObservedObject var server: ServerPinger
  
  var body: some View {
    HStack {
      Text(server.info.name)
      Spacer()
      Circle()
        .foregroundColor((server.pingInfo == nil) ? .red : .green)
        .fixedSize()
    }
  }
}
