//
//  ChatError.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/4/21.
//

import Foundation

enum ChatError: LocalizedError {
  case failedToReadScoreComponent
  case noTranslateKeyInTranslateComponent
  case noTextForStringComponent
  case invalidJSON
  case noKeybindInJSON
  case invalidComponentType
}
