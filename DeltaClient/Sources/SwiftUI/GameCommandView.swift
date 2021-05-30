//
//  GameCommandView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct GameCommandView: View {
  @EnvironmentObject var viewState: ViewState<AppViewState>
  
  @State var command: String = ""
  
  var client: Client
  
  init(serverDescriptor: ServerDescriptor, managers: Managers) {
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
        viewState.returnToPrevious()
      }
    })
  }
}
