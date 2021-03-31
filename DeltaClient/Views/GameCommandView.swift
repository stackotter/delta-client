//
//  GameCommandView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct GameCommandView: View {
  @State var command: String = ""
  
  var client: Client
  
  init(serverInfo: ServerInfo, managers: Managers) {
    self.client = Client(managers: managers, serverInfo: serverInfo)
    
    self.client.play()
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Playing Game! :)")
      TextField("command", text: $command)
        .frame(width: 200, height: nil, alignment: .center)
      Button("run command") {
        self.client.runCommand(command)
      }
    }
  }
}
