import Foundation

enum StorageError: LocalizedError {
  case failedToCreateBackup(Error)
  
  var errorDescription: String? {
    switch self {
      case .failedToCreateBackup(let error):
        return """
        Failed to create a backup.
        Reason: \(error.localizedDescription).
        """
    }
  }
}
