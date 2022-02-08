public struct XboxLiveToken {
  public var token: String
  public var userHash: String
  
  public init(token: String, userHash: String) {
    self.token = token
    self.userHash = userHash
  }
}
