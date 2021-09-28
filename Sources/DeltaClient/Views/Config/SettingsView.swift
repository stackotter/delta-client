import SwiftUI

struct SettingsView: View {
  var body: some View {
    NavigationView {
      List {
        NavigationLink("Accounts", destination: AccountSettingsView().padding())
        NavigationLink("Video", destination: VideoSettingsView().padding())
        NavigationLink("Update", destination: UpdateView().padding())
      }
      .listStyle(SidebarListStyle())
    }
    .navigationTitle("Settings")
  }
}
