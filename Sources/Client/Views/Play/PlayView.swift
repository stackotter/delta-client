import SwiftUI
import DeltaCore

struct PlayView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var controllerHub: ControllerHub

  @State var inGameMenuPresented = false
  @State var readyCount = 0
  @State var takenAccounts: [Account] = []
  @State var takenInputMethods: [InputMethod] = []

  var server: ServerDescriptor
  var paneCount: Int

  init(_ server: ServerDescriptor, paneCount: Int = 1) {
    self.server = server
    self.paneCount = paneCount
  }

  var body: some View {
    ZStack {
      if paneCount == 1 {
        WithSelectedAccount { account in
          GameView(
            connectingTo: server,
            with: account,
            controller: controllerHub.currentController,
            controllerOnly: false,
            inGameMenuPresented: $inGameMenuPresented
          )
        }
      } else {
        HStack(spacing: 0) {
          ForEach(Array(0..<paneCount), id: \.self) { i in
            gamePane(i)
            if i != paneCount - 1 {
              Divider()
            }
          }
        }
      }

      InGameMenu(presented: $inGameMenuPresented)
    }
      .padding(.top, 1)
  }

  var allPlayersChoseControllers: Bool {
    takenInputMethods.allSatisfy(\.isController)
  }

  func gamePane(_ playerIndex: Int) -> some View {
    SelectAccountAndThen(excluding: takenAccounts) { account in
      SelectInputMethodAndThen(excluding: takenInputMethods) { inputMethod in
        // When all player choose controllers, player one gets keyboard and mouse as well to
        // be able to do things such as opening the shared in-game menu.
        let controllerOnly = allPlayersChoseControllers ? playerIndex != 0 : inputMethod.isController

        VStack {
          if readyCount == paneCount {
            GameView(
              connectingTo: server,
              with: account,
              controller: inputMethod.controller,
              controllerOnly: controllerOnly,
              inGameMenuPresented: $inGameMenuPresented
            )
          } else {
            Text("Ready")
          }
        }
        .onAppear {
          readyCount += 1
          takenInputMethods.append(inputMethod)
        }
      } cancellationHandler: {
        appState.update(to: .serverList)
      }
      .onAppear {
        takenAccounts.append(account)
      }
    } cancellationHandler: {
      appState.update(to: .serverList)
    }
    .frame(maxWidth: .infinity)
  }
}
