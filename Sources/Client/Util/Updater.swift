import SwiftUI
import DeltaCore
import ZippyJSON

#if os(macOS)
/// Used to update the client to either the latest successful CI build or the latest GitHub release.
public final class Updater: ObservableObject {
  /// The type of update this updater will perform.
  public var updateType: UpdateType
  
  public enum UpdateType {
    /// Update from GitHub releases.
    case stable
    /// Update from latest CI build.
    case unstable
  }
  
  private var progress = Progress()
  private var queue: OperationQueue
  private var observations: [NSKeyValueObservation] = []
  
  // MARK: SwiftUI
  
  @Published public var fractionCompleted: Double?
  @Published public var stepDescription = ""
  @Published public var version: String?
  @Published public var canCancel = true
  @Published public var branches = [String]()
  @Published public var hasErrored = false
  @Published public var error: Error?

  /// The branch used for unstable updates.
  @Published public var unstableBranch = "dev"
  
  // MARK: Init
  
  public convenience init() {
    self.init(.stable)
  }
  
  public init(_ updateType: UpdateType) {
    self.updateType = updateType
    queue = OperationQueue()
    queue.name = "dev.stackotter.delta-client.update"
    queue.maxConcurrentOperationCount = 1
  }
  
  // MARK: Perform update
  
  /// Starts the requested update asynchronously.
  public func startUpdate() {
    reset()
    queue.addOperation {
      self.updateStep("Getting download URL")
      let downloadURL: URL
      let downloadVersion: String
      do {
        (downloadURL, downloadVersion) = try self.getDownloadURL(self.updateType)
      } catch {
        DeltaClientApp.modalError("Failed to get download URL", safeState: .serverList)
        return
      }
      
      ThreadUtil.runInMain {
        self.version = downloadVersion
      }
      
      self.updateStep("Downloading DeltaClient.app")
      let task = URLSession.shared.dataTask(with: downloadURL, completionHandler: self.finishUpdate)
      self.observations.append(task.progress.observe(\.fractionCompleted, options: [.old, .new], changeHandler: self.updateFractionCompleted))
      self.observations.append(self.progress.observe(\.fractionCompleted, options: [.old, .new], changeHandler: self.updateFractionCompleted))
      task.resume()
    }
  }
  
  /// The completion handler for the download task. Unzips the downloaded file and performs the swap and restart.
  private func finishUpdate(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
    let temp = FileManager.default.temporaryDirectory
    let zipFile = temp.appendingPathComponent("DeltaClient.zip")
    let temp2 = temp.appendingPathComponent("DeltaClient-\(UUID().uuidString)")
    
    queue.addOperation {
      if let data = data {
        do {
          try data.write(to: zipFile)
        } catch {
          DeltaClientApp.modalError("Failed to write download to disk; \(error)", safeState: .serverList)
        }
      }
    }
    
    queue.addOperation {
      self.updateStep("Unzipping DeltaClient.zip")
      self.progress.completedUnitCount = 0
      
      let queue = self.queue
      do {
        try FileManager.default.unzipItem(at: zipFile, to: temp2, skipCRC32: true, progress: self.progress)
        
        if self.updateType == .unstable {
          // Builds downloaded from workflow runs (through nightly.link) have two layers of zip
          self.updateStep("Unzipping a second layer of zip")
          self.progress.completedUnitCount = 0
          try FileManager.default.unzipItem(at: temp2.appendingPathComponent("DeltaClient.zip"), to: temp2, skipCRC32: true, progress: self.progress)
        }
      } catch {
        // Just a workaround because somehow this job unsuspends as when the a subsequent update attempt writes to DeltaClient.zip
        if !queue.isSuspended {
          DeltaClientApp.modalError("Failed to unzip DeltaClient.zip; \(error)", safeState: .serverList)
        }
      }
    }
    
    // Delete the cache to avoid common issues when updating
    queue.addOperation {
      let queue = self.queue
      self.updateStep("Deleting cache")
      sleep(1) // Delay so people have a chance of seeing the message
      do {
        try FileManager.default.removeItem(at: StorageManager.default.cacheDirectory)
      } catch {
        if !queue.isSuspended {
          DeltaClientApp.modalError("Failed to delete cache directory; \(error)", safeState: .serverList)
        }
      }
    }
    
    queue.addOperation {
      self.updateStep("Restarting app in 3")
      sleep(1)
      self.updateStep("Restarting app in 2")
      sleep(1)
      self.updateStep("Restarting app in 1")
      sleep(1)
    }
    
    // Create a background task to replace the app and relaunch
    queue.addOperation {
      ThreadUtil.runInMain {
        self.canCancel = false
      }
    }
    
    queue.addOperation {
      let newApp = temp2.appendingPathComponent("DeltaClient.app").path.replacingOccurrences(of: " ", with: "\\ ")
      let currentApp = Bundle.main.bundlePath.replacingOccurrences(of: " ", with: "\\ ")
      if !self.queue.isSuspended {
        let logFile = StorageManager.default.storageDirectory
          .appendingPathComponent("output.log").path
          .replacingOccurrences(of: " ", with: "\\ ")

        Utils.shell(
          #"nohup sh -c 'sleep 3; rm -rf \#(currentApp); mv \#(newApp) \#(currentApp); open \#(currentApp); open \#(currentApp)' >\#(logFile) 2>&1 &"#
        )

        Foundation.exit(0)
      }
    }
  }
  
  /// Cancels the update if `canCancel` is true.
  public func cancel() {
    queue.cancelAllOperations()
    queue.isSuspended = true
    for observation in observations {
      observation.invalidate()
    }
    observations = []
  }
  
  // MARK: Helper
  
  /// - Returns: A download URL and a version string
  public func getDownloadURL(_ type: UpdateType) throws -> (URL, String) {
    switch type {
      case .stable:
        return try Self.getLatestStableDownloadURL()
      case .unstable:
        return try Self.getLatestUnstableDownloadURL(branch: unstableBranch)
    }
  }
  
  /// Get the download URL for the latest GitHub release.
  ///
  /// - Returns: A download URL and a version string
  private static func getLatestStableDownloadURL() throws -> (URL, String) {
    let decoder = ZippyJSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    let apiURL = URL(string: "https://api.github.com/repos/stackotter/delta-client/releases")!
    
    let data: Data
    let response: [GitHubReleasesAPIResponse]
    do {
      data = try Data(contentsOf: apiURL)
      response = try decoder.decode([GitHubReleasesAPIResponse].self, from: data)
    } catch {
      throw UpdateError.failedToGetGitHubAPIResponse(error)
    }
    
    guard
      let tagName = response.first?.tagName,
      let downloadUrl = response.first?.assets.first?.browserDownloadUrl
    else {
      throw UpdateError.failedToGetDownloadURLFromGitHubReleases
    }
    
    let url = URL(string: downloadUrl)!
    return (url, tagName)
  }
  
  /// Get the download URL for the artifact uploaded by the latest successful GitHub action run.
  ///
  /// - Returns: A download URL and a version string
  private static func getLatestUnstableDownloadURL(branch: String) throws -> (URL, String) {
    let decoder = ZippyJSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    let workflowRuns = try getWorkflowRuns()
    
    // Get the latest relevant run
    guard let run = workflowRuns.first(where: {
      $0.headBranch == branch && $0.conclusion == "success" && $0.name == "Build" && $0.status == "completed"
    }) else {
      throw UpdateError.failedToGetLatestSuccessfulWorkflowRun(branch: "main")
    }
    
    // Get the list of artifacts
    guard
      let artifactsData = try? Data(contentsOf: run.artifactsUrl),
      let artifactsResponse = try? decoder.decode(GitHubArtifactsAPIResponse.self, from: artifactsData),
      let artifact = artifactsResponse.artifacts.first
    else {
      throw UpdateError.failedToGetWorkflowArtifact
    }
    
    // nightly.link exposes public download links to artifacts, because for whatever reason,
    // GitHub requires you to login with a GitHub account to download artifacts
    let url = URL(string: "https://nightly.link/stackotter/delta-client/suites/\(run.checkSuiteId)/artifacts/\(artifact.id)")!
    return (url, "commit \(run.headSha)")
  }
  
  /// Gets a list of GitHub action runs
  ///
  /// - Returns: An array of workflow runs
  private static func getWorkflowRuns() throws -> [GitHubWorkflowAPIResponse.WorkflowRun] {
    let decoder = ZippyJSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    // Get a list of all workflow runs
    let apiURL = URL(string: "https://api.github.com/repos/stackotter/delta-client/actions/workflows/build.yml/runs")!
    do {
      let data = try Data(contentsOf: apiURL)
      let response = try decoder.decode(GitHubWorkflowAPIResponse.self, from: data)
      return response.workflowRuns
    } catch {
      throw UpdateError.failedToGetWorkflowRuns(error)
    }
  }
  
  public func loadUnstableBranches() {
    queue.addOperation {
      self.hasErrored = false
      do {
        let workflowRuns = try Self.getWorkflowRuns()
        var branches = workflowRuns.map(\.headBranch)
        
        // Remove duplicates but maintain order
        var seen = Set<String>()
        branches = branches.filter { seen.insert($0).inserted }

        ThreadUtil.runInMain {
          self.branches = branches
          self.hasErrored = false
        }
      } catch {
        ThreadUtil.runInMain {
          self.hasErrored = true
          log.debug("\(error)")
          self.error = error
        }
      }
    }
  }
  
  /// Resets the updater back to its initial state
  private func reset() {
    ThreadUtil.runInMain {
      stepDescription = ""
      fractionCompleted = nil
      version = nil
      canCancel = true
      queue = OperationQueue()
      queue.name = "dev.stackotter.delta-client.update"
      queue.maxConcurrentOperationCount = 1
      progress = Progress()
    }
  }
  
  private func updateFractionCompleted(_ progress: Progress, _ change: NSKeyValueObservedChange<Double>) {
    ThreadUtil.runInMain {
      fractionCompleted = change.newValue ?? 0
    }
  }
  
  private func updateStep(_ name: String) {
    ThreadUtil.runInMain {
      stepDescription = name
    }
  }
}
#endif
