//
//  StorageError.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 27/6/21.
//

import Foundation

enum StorageError: LocalizedError {
  case failedToCreateBackup(Error)
}
