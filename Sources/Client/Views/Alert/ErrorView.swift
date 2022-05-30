import SwiftUI
import DeltaCore

struct ErrorView: View {
  @EnvironmentObject var modalState: StateWrapper<ModalState>
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  let message: String
  let safeState: AppState?
  
  var body: some View {
    VStack {
      if message.contains("§") {
        LegacyFormattedTextView(legacyString: message, fontSize: FontUtil.systemFontSize(for: .regular))
      } else {
        Text(message)
      }
      Button("OK") {
        if let nextState = safeState {
          appState.update(to: nextState)
        }
        modalState.update(to: .none)
      }
      .buttonStyle(PrimaryButtonStyle())
      .frame(width: 100)
    }
    .navigationTitle("Error")
    .frame(width: 500)
  }
}
