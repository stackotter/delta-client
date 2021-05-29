//
//  AccountIdentifier.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 29/5/21.
//

import Foundation

struct AccountIdentifier: Hashable {
  var uuid: String
  var type: AccountType
}
