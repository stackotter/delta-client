//
//  ErrorView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 27/6/21.
//

import SwiftUI

struct ErrorView: View {
  @EnvironmentObject var modalState: StateWrapper<ModalState>
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  let message: String
  let safeState: AppState?
  
  var body: some View {
    VStack {
      Text(message)
      Button("Ok") {
        if let nextState = safeState {
          appState.update(to: nextState)
        }
        modalState.update(to: .none)
      }
    }
    .navigationTitle("Error")
  }
}
