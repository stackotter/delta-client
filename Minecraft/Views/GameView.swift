//
//  GameView.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 11/12/20.
//

import SwiftUI

struct GameView: View {
  @ObservedObject var server: Server
  
  var body: some View {
    VStack {
      Text("Playing Game! :)")
    }
  }
}
