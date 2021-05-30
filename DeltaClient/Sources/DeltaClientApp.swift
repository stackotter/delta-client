//
//  DeltaClientApp.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 10/12/20.
//

import SwiftUI

@main
struct DeltaClientApp: App {
  public static var eventManager = EventManager<AppEvent>()

  @ObservedObject var state = ViewState<AppStateEnum>(initialState: .loading(message: "loading game.."))

  enum AppStateEnum {
    case loading(message: String)
    case error(message: String)
    case loaded(managers: Managers)
  }

  init() {
    DeltaClientApp.eventManager.registerEventHandler(handleEvent)

    // run app startup sequence
    let thread = DispatchQueue(label: "startup")
    let startupSequence = StartupSequence()
    thread.async {
      do {
        try startupSequence.run()
      } catch {
        DeltaClientApp.eventManager.triggerEvent(.error("failed to complete startup: \(error)"))
      }
    }
  }

  static func triggerError(_ message: String) {
    eventManager.triggerEvent(.error(message))
  }

  func handleEvent(_ event: AppEvent) {
    switch event {
      case .loadingScreenMessage(let message):
        Logger.info(message)
        state.update(to: .loading(message: message))
      case .loadingComplete(let managers):
        state.update(to: .loaded(managers: managers))
      case .error(let message):
        Logger.error(message)
        state.update(to: .error(message: message))
      default:
        break
    }
  }

  var body: some Scene {
    WindowGroup {
      Group {
        switch state.value {
          case .error(let message):
            Text(message)
              .navigationTitle("Error")
              .toolbar(content: {
                switch state.previous {
                  case .loaded(let managers):
                    Button("dismiss") {
                      state.update(to: .loaded(managers: managers))
                    }
                  default:
                    Text("")
                }
              })
          case .loading(let message):
            Text(message)
              .navigationTitle("Delta Client")
              .toolbar {
                Text("")
                  .frame(width: 10)
              }
          case .loaded(let managers):
            AppView(managers: managers)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
