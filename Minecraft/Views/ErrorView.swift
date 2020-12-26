//
//  ErrorView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 26/12/20.
//

import SwiftUI

struct ErrorView: View {
  @ObservedObject var viewState: ViewState
  
  var body: some View {
    VStack(spacing: 16) {
      Text("Error")
        .font(.largeTitle)
      Text(viewState.errorMessage!)
        .font(.title)
    }
  }
}
