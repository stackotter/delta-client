//
//  GameCommandView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct GameCommandView: View {
  @State var command: String = ""
  
  var client: Client
  var eventManager: EventManager
  
  init(serverDescriptor: ServerDescriptor, managers: Managers) {
    self.eventManager = managers.eventManager
    self.client = Client(managers: managers, serverDescriptor: serverDescriptor)
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
    .navigationTitle("Delta Client")
    .toolbar(content: {
      Button("leave") {
        client.quit()
        eventManager.triggerEvent(.leaveServer)
      }
    })
  }
}
