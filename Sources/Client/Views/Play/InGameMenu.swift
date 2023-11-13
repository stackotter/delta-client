import SwiftUI

struct InGameMenu: View {
  enum InGameMenuState {
    case menu
    case settings
  }

  @EnvironmentObject var appState: StateWrapper<AppState>

  @Binding var presented: Bool
  @State var state: InGameMenuState = .menu

  init(presented: Binding<Bool>) {
    _presented = presented
  }
  
  var body: some View {
    if presented {    
      GeometryReader { geometry in
        VStack {
          switch state {
            case .menu:
              VStack {
                Button("Back to game") {
                  presented = false
                }
                  .keyboardShortcut(.escape, modifiers: [])
                  .buttonStyle(PrimaryButtonStyle())

                Button("Settings") { 
                  state = .settings
                }
                  .buttonStyle(SecondaryButtonStyle())

                Button("Disconnect") {
                  appState.update(to: .serverList)
                }
                  .buttonStyle(SecondaryButtonStyle())
              }
              .frame(width: 200)
            case .settings:
              SettingsView(isInGame: true) {
                state = .menu
              }
          }
        }
          .frame(width: geometry.size.width, height: geometry.size.height)
          .background(Color.black.opacity(0.702), alignment: .center)
      }
    }
  }
}
