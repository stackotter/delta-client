//
//  AccountType.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 29/5/21.
//

import Foundation

public enum AccountType: String, CaseIterable, Identifiable, Codable {
  case mojang
  case offline
  case microsoft
  
  public var id: String { self.rawValue }
}
