struct XboxLiveToken {
  var token: String
  var userHash: String
  
  init(token: String, userHash: String) {
    self.token = token
    self.userHash = userHash
  }
}
