import SwiftUI

struct WarningView: View {
  @EnvironmentObject var modalState: StateWrapper<ModalState>
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  let message: String
  
  var body: some View {
    VStack {
      Text(message)
      Button("OK") {
        modalState.update(to: .none)
      }
      .buttonStyle(PrimaryButtonStyle())
      .frame(width: 100)
    }
    .navigationTitle("Warning")
    .frame(width: 200)
  }
}
