import Foundation

enum ChatError: LocalizedError {
  case failedToReadScoreComponent
  case noTranslateKeyInTranslateComponent
  case noTextForStringComponent
  case invalidJSON
  case noKeybindInJSON
  case invalidComponentType
}
