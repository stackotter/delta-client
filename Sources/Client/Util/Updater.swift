#if os(macOS)
import SwiftUI
import DeltaCore

/// An error thrown by ``Updater``.
enum UpdaterError: LocalizedError {
  case failedToGetDownloadURL
  case failedToGetDownloadURLFromGitHubReleases
  case alreadyUpToDate
  case failedToGetBranches
  case failedToGetGitHubAPIResponse
  case failedToDownloadUpdate
  case failedToSaveDownload
  case failedToUnzipUpdate
  case failedToDeleteCache
  case invalidReleaseURL
  case invalidNightlyURL
  case invalidGitHubComparisonURL
  
  var errorDescription: String? {
    switch self {
      case .failedToGetDownloadURL:
        return "Failed to get download URL."
      case .failedToGetDownloadURLFromGitHubReleases:
        return "Failed to get download URL from GitHub Releases."
      case .alreadyUpToDate:
        return "You are already up to date."
      case .failedToGetBranches:
        return "Failed to get branches."
      case .failedToGetGitHubAPIResponse:
        return "Failed to get GitHub API response."
      case .failedToDownloadUpdate:
        return "Failed to download update."
      case .failedToSaveDownload:
        return "Failed to save download to disk."
      case .failedToUnzipUpdate:
        return "Failed to unzip update."
      case .failedToDeleteCache:
        return "Failed to delete cache."
      case .invalidReleaseURL:
        return "Invalid release URL."
      case .invalidNightlyURL:
        return "Invalid nightly URL."
      case .invalidGitHubComparisonURL:
        return "Invalid GitHub comparison URL."
    }
  }
}

/// An update to perform.
enum Update {
  /// Update from GitHub releases.
  case latestRelease
  /// Update from latest CI build.
  case nightly(branch: String)

  /// Whether the update is nightly or not.
  var isNightly: Bool {
    switch self {
      case .latestRelease:
        return false
      case .nightly:
        return true
    }
  }
}

/// A download for an update.
struct Download {
  /// The download's URL.
  var url: URL
  /// The version to display.
  var version: String
}

/// Used to update the client to either the latest successful CI build or the latest GitHub release.
enum Updater {
  /// A step in an update. Used to track progress.
  enum UpdateStep: TaskStep {
    case downloadUpdate
    case unzipUpdate
    case unzipUpdateSecondLayer
    case deleteCache
    case tMinus3
    case tMinus2
    case tMinus1

    var message: String {
      switch self {
        case .downloadUpdate:
          return "Downloading update"
        case .unzipUpdate:
          return "Unzipping update"
        case .unzipUpdateSecondLayer:
          return "Unzipping second layer of update"
        case .deleteCache:
          return "Deleting cache"
        case .tMinus3:
          return "Restarting app in 3"
        case .tMinus2:
          return "Restarting app in 2"
        case .tMinus1:
          return "Restarting app in 1"
      }
    }

    var relativeDuration: Double {
      switch self {
        case .downloadUpdate:
          return 10
        case .unzipUpdate:
          return 2
        case .unzipUpdateSecondLayer:
          return 2
        case .deleteCache:
          return 1
        case .tMinus3:
          return 1
        case .tMinus2:
          return 1
        case .tMinus1:
          return 1
      }
    }
  }

  /// Performs a given update. Once the update's version string is known, `displayVersion`
  /// is updated (allowing a UI to display the version before the update has finished).
  /// `storage` is used to delete the cache before restarting the app.
  ///
  /// Never returns (unless an error occurs) because it restarts the app to allow the
  /// update to take effect.
  static func performUpdate(download: Download, isNightly: Bool, storage: StorageDirectory, progress: TaskProgress<UpdateStep>? = nil) async throws -> Never {
    let progress = progress ?? TaskProgress()
    // Download the release
    let data = try await progress.perform(.downloadUpdate) { observeStepProgress in
      try await withCheckedThrowingContinuation { continuation in
        let task = URLSession.shared.dataTask(with: download.url) { data, response, error in
          if let data = data {
          continuation.resume(returning: data)
          } else {
            var richError: any LocalizedError = UpdaterError.failedToDownloadUpdate
            if let error = error {
              richError = richError.becauseOf(error)
            }
            continuation.resume(throwing: richError)
          }
        }
        observeStepProgress(task.progress)
        task.resume()
      }
    }

    try Task.checkCancellation()

    let temp = FileManager.default.temporaryDirectory
    let zipFile = temp.appendingPathComponent("DeltaClient.zip")
    let outputDirectory = temp.appendingPathComponent("DeltaClient-\(UUID().uuidString)")

    do {
      try data.write(to: zipFile)
    } catch {
      throw UpdaterError.failedToSaveDownload.becauseOf(error)
    }

    try Task.checkCancellation()

    try await progress.perform(.unzipUpdate) { observeStepProgress in
      do {
        let progress = Progress()
        observeStepProgress(progress)
        try FileManager.default.unzipItem(at: zipFile, to: outputDirectory, skipCRC32: true, progress: progress)
      } catch {
        throw UpdaterError.failedToUnzipUpdate.becauseOf(error)
      }
    }

    try Task.checkCancellation()

    // Nightly builds have two layers of zip for whatever reason
    try await progress.perform(.unzipUpdateSecondLayer, if: isNightly) { observeStepProgress in
      let progress = Progress()
      observeStepProgress(progress)

      try FileManager.default.unzipItem(
        at: outputDirectory.appendingPathComponent("DeltaClient.zip"),
        to: outputDirectory,
        skipCRC32: true,
        progress: progress
      )
    }

    try Task.checkCancellation()

    // Delete the cache to avoid common issues which can occur after updating
    try progress.perform(.deleteCache) {
      do {
        try FileSystem.remove(storage.cacheDirectory)
      } catch {
        throw UpdaterError.failedToDeleteCache.becauseOf(error)
      }
    }

    try Task.checkCancellation()
    progress.update(to: .tMinus3)
    try await Task.sleep(nanoseconds: 1_000_000_000)
    try Task.checkCancellation()
    progress.update(to: .tMinus2)
    try await Task.sleep(nanoseconds: 1_000_000_000)
    try Task.checkCancellation()
    progress.update(to: .tMinus1)
    try await Task.sleep(nanoseconds: 1_000_000_000)
    try Task.checkCancellation()

    // Create a background task to replace the app and relaunch
    let newApp = outputDirectory
      .appendingPathComponent("DeltaClient.app").path
      .replacingOccurrences(of: " ", with: "\\ ")
    let currentApp = Bundle.main.bundlePath.replacingOccurrences(of: " ", with: "\\ ")
    let logFile = storage.baseDirectory
      .appendingPathComponent("output.log").path
      .replacingOccurrences(of: " ", with: "\\ ")

    // TODO: Refactor to avoid potential for command injection attacks (relatively low impact anyway,
    //   Delta Client doesn't run with elevated privileges, and this requires user interaction).
    Utils.shell(
      #"nohup sh -c 'sleep 3; rm -rf \#(currentApp); mv \#(newApp) \#(currentApp); open \#(currentApp); open \#(currentApp)' >\#(logFile) 2>&1 &"#
    )

    Foundation.exit(0)
  }

  /// Gets the download for a given update.
  static func getDownload(for update: Update) throws -> Download {
    switch update {
      case .latestRelease:
        return try getLatestReleaseDownload()
      case .nightly(let branch):
        return try getLatestNightlyDownload(branch: branch)
    }
  }

  /// Gets the download for the latest GitHub release.
  static func getLatestReleaseDownload() throws -> Download {
    var decoder = CustomJSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let apiURL = URL(string: "https://api.github.com/repos/stackotter/delta-client/releases")!

    let data: Data
    let response: [GitHubReleasesAPIResponse]
    do {
      data = try Data(contentsOf: apiURL)
      response = try decoder.decode([GitHubReleasesAPIResponse].self, from: data)
    } catch {
      throw UpdaterError.failedToGetGitHubAPIResponse.becauseOf(error)
    }

    guard
      let tagName = response.first?.tagName,
      let downloadURL = response.first?.assets.first?.browserDownloadURL
    else {
      throw UpdaterError.failedToGetDownloadURLFromGitHubReleases
    }

    guard let url = URL(string: downloadURL) else {
      throw UpdaterError.invalidReleaseURL.with("URL", downloadURL)
    }
    return Download(url: url, version: tagName)
  }

  /// Gets the download for the artifact uploaded by the latest successful GitHub action run
  /// on a given branch.
  static func getLatestNightlyDownload(branch: String) throws -> Download {
    let branches = try getBranches()
    guard let commit = (branches.filter { $0.name == branch }.first?.commit) else {
      throw UpdaterError.failedToGetDownloadURL.with("Reason", "Branch '\(branch)' doesn't exist.")
    }

    if case let .commit(currentCommit) = DeltaClientApp.version {
      guard currentCommit != commit.sha else {
        throw UpdaterError.alreadyUpToDate.with("Current commit", currentCommit)
      }
    }

    let hash = commit.sha.prefix(7)
    let url = "https://backend.deltaclient.app/download/\(branch)/latest/DeltaClient.app.zip"
    guard let url = URL(string: url) else {
      throw UpdaterError.invalidNightlyURL.with("URL", url)
    }

    return Download(url: url, version: "commit \(hash) (latest)")
  }

  /// Gets basic information about all branches of the Delta Client GitHub repository.
  static func getBranches() throws -> [GitHubBranch] {
    let url = URL(string: "https://api.github.com/repos/stackotter/delta-client/branches")!
    do {
      let data = try Data(contentsOf: url)
      let response = try CustomJSONDecoder().decode([GitHubBranch].self, from: data)
      return response
    } catch {
      throw UpdaterError.failedToGetBranches.becauseOf(error)
    }
  }

  /// Compares two gitrefs in the Delta Client GitHub repository.
  static func compareGitRefs(_ first: String, _ second: String) throws -> GitHubComparison.Status {
    let url = "https://api.github.com/repos/stackotter/delta-client/compare/\(first)...\(second)"
    guard let url = URL(string: url) else {
      throw UpdaterError.invalidGitHubComparisonURL.with("URL", url)
    }
    let data = try Data(contentsOf: url)
    return try CustomJSONDecoder().decode(GitHubComparison.self, from: data).status
  }
  
  /// Checks if the user is on the main branch and a newer commit is available.
  static func isUpdateAvailable() throws -> Bool {
    let currentVersion = DeltaClientApp.version
    guard case let .commit(commit) = currentVersion else {
      return false
    }

    // TODO: When releases are supported again, check for newer releases if the user if on a release build.
    let status = try compareGitRefs(commit, "main")
    return status == .behind
  }
}
#endif
