import SwiftUI

struct InGameMenu: View {
  enum InGameMenuState {
    case menu
    case settings
  }

  @EnvironmentObject var appState: StateWrapper<AppState>

  @Binding var presented: Bool
  @State var state: InGameMenuState = .menu

  #if os(tvOS)
  @FocusState var focusState: FocusElements?

  func moveFocus(_ direction: MoveCommandDirection) {
    if let focusState = focusState {
      let step: Int
      switch direction {
        case .down:
          step = 1
        case .up:
          step = -1
        case .left, .right:
          return
      }
      let count = FocusElements.allCases.count
      // Add an extra count before taking the modulo cause Swift's mod operator isn't
      // the real mathematical modulo.
      let index = (focusState.rawValue + step + count) % count
      self.focusState = FocusElements.allCases[index]
    }
  }

  enum FocusElements: Int, CaseIterable {
    case backToGame
    case settings
    case disconnect
  }
  #endif

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
                  #if os(tvOS)
                  .focused($focusState, equals: .backToGame)
                  .buttonStyle(PrimaryButtonStyle())
                  #else
                  .keyboardShortcut(.escape, modifiers: [])
                  #endif

                Button("Settings") { 
                  state = .settings
                }
                  #if os(tvOS)
                  .focused($focusState, equals: .settings)
                  .buttonStyle(SecondaryButtonStyle())
                  #endif

                Button("Disconnect") {
                  appState.update(to: .serverList)
                }
                  #if os(tvOS)
                  .focused($focusState, equals: .disconnect)
                  .buttonStyle(SecondaryButtonStyle())
                  #endif
              }
              #if !os(tvOS)
              .frame(width: 200)
              #endif
            case .settings:
              SettingsView(isInGame: true) {
                state = .menu
              }
          }
        }
          .frame(width: geometry.size.width, height: geometry.size.height)
          .background(Color.black.opacity(0.702), alignment: .center)
          #if os(tvOS)
          .onAppear {
            focusState = .backToGame
          }
          .focusSection()
          #endif
      }
    }
  }
}
