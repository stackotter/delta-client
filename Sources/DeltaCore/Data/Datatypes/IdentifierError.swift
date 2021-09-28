//
//  IdentifierError.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

public enum IdentifierError: LocalizedError {
  case invalidIdentifier
  case invalidIdentifierString(String)
  case emptyString
}
