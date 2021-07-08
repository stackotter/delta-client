//
//  SettingsView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/7/21.
//

import SwiftUI

struct SettingsView: View {
  var body: some View {
    NavigationView {
      List {
        NavigationLink("Accounts", destination: AccountSettingsView())
      }
      .listStyle(SidebarListStyle())
    }
    .navigationTitle("Settings")
  }
}
