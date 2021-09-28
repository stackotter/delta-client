import Foundation

public struct Config: Codable {
  public var clientToken: String
  public var selectedAccount: String?
  public var selectedAccountType: String?
  public var mojangAccounts: [String: MojangAccount]
  public var offlineAccounts: [String: OfflineAccount]
  public var servers: [ServerDescriptor]
  
  public init(
    clientToken: String,
    selectedAccount: String?,
    selectedAccountType: String?,
    mojangAccounts: [String: MojangAccount],
    offlineAccounts: [String: OfflineAccount],
    servers: [ServerDescriptor])
  {
    self.clientToken = clientToken
    self.selectedAccount = selectedAccount
    self.selectedAccountType = selectedAccountType
    self.mojangAccounts = mojangAccounts
    self.offlineAccounts = offlineAccounts
    self.servers = servers
  }

  public static func createDefault() -> Config {
    return Config(
      clientToken: UUID().uuidString, // random uuid
      selectedAccount: nil,
      selectedAccountType: nil,
      mojangAccounts: [:],
      offlineAccounts: [:],
      servers: []
    )
  }
}
