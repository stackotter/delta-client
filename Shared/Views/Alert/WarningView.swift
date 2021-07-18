//
//  WarningView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 27/6/21.
//

import SwiftUI

struct WarningView: View {
  @EnvironmentObject var modalState: StateWrapper<ModalState>
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  let message: String
  
  var body: some View {
    VStack {
      Text(message)
      Button("Ok") {
        modalState.update(to: .none)
      }
      .buttonStyle(PrimaryButtonStyle())
      .frame(width: 100)
    }
    .navigationTitle("Warning")
    .frame(width: 200)
  }
}
