//
//  DeltaCoreApp.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 10/12/20.
//

import SwiftUI
import Puppy

// TODO: severely reorganise and clean up DeltaCoreApp
@main
struct DeltaCoreApp: App {
  @ObservedObject var state = ViewState<AppStateEnum>(initialState: .loading(message: "loading game.."))
  
  // eventually remove the need for eventManager, it's old and clunky
  public static var eventManager = EventManager<AppEvent>()

  enum AppStateEnum {
    case loading(message: String)
    case error(message: String)
    case loaded(managers: Managers)
  }

  init() {
    // get log level from command-line arguments
    let logLevel = UserDefaults.standard.string(forKey: "logLevel")
    var level: LogLevel?
    if let logLevel = logLevel {
      switch logLevel {
        case "trace": level = .trace
        case "debug": level = .debug
        case "info": level = .info
        case "warning": level = .warning
        case "error": level = .error
        default:
          log.warning("Invalid argument for logLevel. Valid values: trace, debug, info, warning and error")
          level = .info
      }
    } else {
      level = .info
    }
    if let level = level {
      log.updateConsoleLogLevel(to: level)
    }
    
    DeltaCoreApp.eventManager.registerEventHandler(handleEvent)

    // run app startup sequence
    let thread = DispatchQueue(label: "startup")
    let startupSequence = StartupSequence()
    thread.async {
      do {
        try startupSequence.run()
      } catch {
        DeltaCoreApp.eventManager.triggerEvent(.error("failed to complete startup: \(error)"))
      }
    }
  }

  static func triggerError(_ message: String) {
    eventManager.triggerEvent(.error(message))
  }

  func handleEvent(_ event: AppEvent) {
    switch event {
      case .loadingScreenMessage(let message):
        log.info(message)
        state.update(to: .loading(message: message))
      case .loadingComplete(let managers):
        state.update(to: .loaded(managers: managers))
      case .error(let message):
        log.error(message)
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
