//
//  PingIndicator.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/7/21.
//

import SwiftUI

struct PingIndicator: View {
  let color: Color
  
  var body: some View {
    Circle()
      .foregroundColor(color)
      .fixedSize()
  }
}
