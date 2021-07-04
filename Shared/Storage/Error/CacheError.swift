//
//  CacheError.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

enum CacheError: LocalizedError {
  case noSuchCache
  case failedToSerialize
  case failedToWrite
  case failedToDeserialize
  case failedToRead
}
