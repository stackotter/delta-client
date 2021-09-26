//
//  SecondaryButtonStyle.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 11/7/21.
//

import SwiftUI

struct SecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      Spacer()
      configuration.label.foregroundColor(.white)
      Spacer()
    }
    .padding(6)
    .background(Color.secondary.brightness(configuration.isPressed ? 0 : -0.15).cornerRadius(4))
  }
}
