//
//  DismissibleErrorView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI

struct DismissibleErrorView: View {
  let message: String
  
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  var body: some View {
    Text(message)
      .navigationTitle("Error")
      .toolbar {
        Button("dismiss") {
          appState.update(to: .serverList)
        }
      }
  }
}
