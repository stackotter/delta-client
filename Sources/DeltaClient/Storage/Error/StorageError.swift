import Foundation

enum StorageError: LocalizedError {
  case failedToCreateBackup(Error)
}
