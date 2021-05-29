//
//  Account.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 15/5/21.
//

import Foundation

protocol Account: Codable {
  var id: String { get set }
  var profileId: String { get set }
  var name: String { get set }
}
