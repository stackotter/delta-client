import Foundation
import DeltaCore

/// App states
indirect enum AppState: Equatable {
  case serverList
  case editServerList
  case accounts
  case login
  case directConnect
  case playServer(ServerDescriptor, paneCount: Int)
  case settings(SettingsState?)
}
