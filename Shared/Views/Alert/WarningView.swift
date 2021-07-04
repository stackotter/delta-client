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
    Text(message)
      .navigationTitle("Warning")
      .toolbar {
        Button("dismiss") {
          modalState.update(to: .none)
        }
      }
  }
}
