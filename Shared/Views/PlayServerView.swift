//
//  PlayServerView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

struct PlayServerView: View {
  var serverDescriptor: ServerDescriptor
  
  var body: some View {
    Group {
      Text("Playing on \(serverDescriptor.name)")
    }
  }
}
