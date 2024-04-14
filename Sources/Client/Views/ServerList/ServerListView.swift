import SwiftUI
import DeltaCore

struct ServerListView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var managedConfig: ManagedConfig
  @EnvironmentObject var modal: Modal

  @State var pingers: [Pinger] = []
  @State var lanServerEnumerator: LANServerEnumerator?
  @State var updateAvailable = false

  var body: some View {
    NavigationView {
      List {
        // Server list
        if !pingers.isEmpty {
          ForEach(pingers, id: \.self) { pinger in
            NavigationLink(destination: ServerDetail(pinger: pinger)) {
              ServerListItem(pinger: pinger)
            }
          }
        } else {
          Text("no servers").italic()
        }

        #if !os(tvOS)
          Divider()
        #endif

        if let lanServerEnumerator = lanServerEnumerator {
          LANServerList(lanServerEnumerator: lanServerEnumerator)
        } else {
          Text("LAN scan failed").italic()
        }

        #if os(tvOS)
          Divider()

          Button("Edit servers") {
            appState.update(to: .editServerList)
          }

          Button("Refresh servers") {
            refresh()
          }

          Button("Direct connect") {
            appState.update(to: .directConnect)
          }

          Button("Settings") {
            appState.update(to: .settings(nil))
          }
        #else
          HStack {
            // Edit server list
            IconButton("square.and.pencil") {
              appState.update(to: .editServerList)
            }

            // Refresh server list (ping all servers) and discovered LAN servers
            IconButton("arrow.clockwise") {
              refresh()
            }

            // Direct connect
            IconButton("personalhotspot") {
              appState.update(to: .directConnect)
            }

            #if os(iOS) || os(tvOS)
              // Settings
              IconButton("gear") {
                appState.update(to: .settings(nil))
              }
            #endif
          }
        #endif

        if (updateAvailable) {
          Button("Update") {
            appState.update(to: .settings(.update))
          }.padding(.top, 5)
        }
      }
      #if !os(tvOS)
      // TODO: Does this even do anything?
      .listStyle(SidebarListStyle())
      #endif
    }
    .onAppear {
      // Check for updates
      Task {
        await checkForUpdates()
      }

      // Create server pingers
      let servers = managedConfig.config.servers
      pingers = servers.map { server in
        Pinger(server)
      }

      refresh()

      // TODO: The whole EventBus architecture is pretty unwieldy at the moment,
      //   all this code just to create and start a lan server enumerator?
      // Create LAN server enumerator
      let eventBus = EventBus()
      lanServerEnumerator = LANServerEnumerator(eventBus: eventBus)
      eventBus.registerHandler { event in
        switch event {
          case let event as ErrorEvent:
            log.warning("\(event.message ?? "Error"): \(event.error)")
          default:
            break
        }
      }

      do {
        try lanServerEnumerator?.start()
      } catch {
        modal.error(RichError("Failed to start LAN server enumerator.").becauseOf(error))
      }
    }
    .onDisappear {
      lanServerEnumerator?.stop()
    }
  }

  // Check if any Delta Client updates are available. Does nothing if not on macOS.
  func checkForUpdates() async {
    #if os(macOS)
      do {
        let result = try Updater.isUpdateAvailable()
        await MainActor.run {
          updateAvailable = result
        }
      } catch {
        modal.error(RichError("Failed to check for updates").becauseOf(error))
      }
    #endif
  }

  /// Ping all servers and clear discovered LAN servers.
  func refresh() {
    for pinger in pingers {
      try? pinger.ping()
    }

    lanServerEnumerator?.clear()
  }
}
