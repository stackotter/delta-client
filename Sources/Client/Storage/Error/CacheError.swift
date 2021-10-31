import Foundation

enum CacheError: LocalizedError {
  case noSuchCache
  case failedToSerialize
  case failedToWrite
  case failedToDeserialize
  case failedToRead
}
