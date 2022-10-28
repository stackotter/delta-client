import SwiftUI
import DeltaCore

struct ServerListView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  
  @State var pingers: [Pinger]
  
  var lanServerEnumerator: LANServerEnumerator?
  var updateAvailable: Bool = false
  
  init() {
    // Create server pingers
    let servers = ConfigManager.default.config.servers
    _pingers = State(initialValue: servers.map { server in
      Pinger(server)
    })
    
    // Attempt to create LAN server enumerator
    let eventBus = EventBus()
    do {
      lanServerEnumerator = try LANServerEnumerator(eventBus: eventBus)
      eventBus.registerHandler { event in
        switch event {
          case let event as ErrorEvent:
            log.warning("\(event.message ?? "Error"): \(event.error)")
          default:
            break
        }
      }
    } catch {
      log.warning("Failed to start LAN server enumerator: \(error)")
    }
    
    // Start pinging and enumerating
    refresh()
    lanServerEnumerator?.start()
    
    do {
      _ = try Updater.getLatestUnstableDownloadURL(branch: "main")
      updateAvailable = true
    } catch {
      // getLatestUnstableDownloadURL will throw UpdateError.alreadyUpToDate if an update is not available
    }
  }
  
  /// Ping all servers again and clear discovered LAN servers.
  func refresh() {
    for pinger in pingers {
      try? pinger.ping()
    }
    
    lanServerEnumerator?.clear()
  }
  
  // Navigate to update settings view
  func update() {
    appState.update(to: .settings(.update))
  }
  
  var body: some View {
    NavigationView {
      List {
        if !pingers.isEmpty {
          ForEach(pingers, id: \.self) { pinger in
            NavigationLink(destination: ServerDetail(pinger: pinger)) {
              ServerListItem(pinger: pinger)
            }
          }
        } else {
          Text("no servers").italic()
        }
        
        Divider()
        
        if let lanServerEnumerator = lanServerEnumerator {
          LANServerList(lanServerEnumerator: lanServerEnumerator)
        } else {
          Text("LAN scan failed").italic()
        }
        
        HStack {
          // Edit
          IconButton("square.and.pencil") {
            appState.update(to: .editServerList)
          }
          
          // Refresh servers
          IconButton("arrow.clockwise") {
            refresh()
          }
          
          // Direct connect
          IconButton("personalhotspot") {
            appState.update(to: .directConnect)
          }
        }
        
        if (updateAvailable) {
          Button("Update", action: update)
        }
      }
      .listStyle(SidebarListStyle())
    }.onDisappear {
      lanServerEnumerator?.stop()
    }
  }
}
