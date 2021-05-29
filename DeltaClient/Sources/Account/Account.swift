//
//  Account.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/5/21.
//

import Foundation

protocol Account: Codable {
  var id: String { get set }
  var profiles: [String: Profile] { get set }
  var selectedProfile: String { get set }
}

extension Account {
  mutating func selectProfile(uuid: String) {
    ThreadUtil.runInMain {
      selectedProfile = uuid
    }
  }
  
  func getSelectedProfile() -> Profile? {
    return profiles[selectedProfile]
  }
}
