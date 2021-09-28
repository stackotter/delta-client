//
//  Updater.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 28/9/21.
//

import Foundation
import SwiftUI
import DeltaCore

/// Used to update the client to either the latest successful CI build or the latest GitHub release.
class Updater: ObservableObject {
  var updateType: UpdateType
  
  enum UpdateType {
    case stable
    case unstable
  }
  
  private var progress = Progress()
  private var queue: OperationQueue
  private var observations: [NSKeyValueObservation] = []
  
  @Published var fractionCompleted: Double? = nil
  @Published var stepDescription = ""
  @Published var version: String?
  @Published var canCancel = true
  
  convenience init() {
    self.init(.stable)
  }
  
  init(_ updateType: UpdateType) {
    self.updateType = updateType
    queue = OperationQueue()
    queue.name = "dev.stackotter.delta-client.update"
    queue.maxConcurrentOperationCount = 1
  }
  
  /// Starts the requested update asynchronously.
  func startUpdate() {
    reset()
    queue.addOperation {
      self.updateStep("Getting download URL")
      let downloadURL: URL
      let downloadVersion: String
      do {
        (downloadURL, downloadVersion) = try Self.getDownloadURL(self.updateType)
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
  
  /// Cancels the update if `canCancel` is true.
  func cancel() {
    queue.cancelAllOperations()
    queue.isSuspended = true
    for observation in observations {
      observation.invalidate()
    }
    observations = []
  }
  
  /// - Returns: A download URL and a version string
  static func getDownloadURL(_ type: UpdateType) throws -> (URL, String) {
    switch type {
      case .stable:
        return try getLatestStableDownloadURL()
      case .unstable:
        return try getLatestUnstableDownloadURL()
    }
  }
  
  /// Get the download URL for the latest GitHub release.
  ///
  /// - Returns: A download URL and a version string
  private static func getLatestStableDownloadURL() throws -> (URL, String) {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    let apiURL = URL(string: "https://api.github.com/repos/stackotter/delta-client/releases")!
    
    let data: Data
    let response: [GitHubReleasesAPIResponse]
    do {
      data = try Data(contentsOf: apiURL)
      try data.write(to: URL(fileURLWithPath: "/Users/rohanvanklinken/Desktop/response.json"))
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
  private static func getLatestUnstableDownloadURL() throws -> (URL, String) {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    // Get a list of all workflow runs
    let apiURL = URL(string: "https://api.github.com/repos/stackotter/delta-client/actions/workflows/main.yml/runs")!
    guard
      let data = try? Data(contentsOf: apiURL),
      let response = try? decoder.decode(GitHubWorkflowAPIResponse.self, from: data)
    else {
      throw UpdateError.failedToGetWorkflowRuns
    }
    
    // Get the latest relevant run
    guard let run = response.workflowRuns.first(where: {
      $0.event == "push" && $0.headBranch == "main" && $0.conclusion == "success" && $0.name == "Build" && $0.status == "completed"
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
    
    // nightly.link exposes public download links to artifacts, because for whatever reason, GitHub requires you to login with a GitHub account to download artifacts
    let url = URL(string: "https://nightly.link/stackotter/delta-client/suites/\(run.checkSuiteId)/artifacts/\(artifact.id)")!
    return (url, "commit \(run.headSha)")
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
        try FileManager.default.unzipItem(at: zipFile, to: temp2, progress: self.progress)
        
        if self.updateType == .unstable {
          // Builds downloaded from workflow runs (through nightly.link) have two layers of zip
          self.updateStep("Unzipping a second layer of zip")
          self.progress.completedUnitCount = 0
          try FileManager.default.unzipItem(at: temp2.appendingPathComponent("DeltaClient.zip"), to: temp2, progress: self.progress)
        }
      } catch {
        // Just a workaround because somehow this job unsuspends as when the a subsequent update attempt writes to DeltaClient.zip
        if !queue.isSuspended {
          DeltaClientApp.modalError("Failed to unzip DeltaClient.zip; \(error)", safeState: .serverList)
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
      let newApp = temp2.appendingPathComponent("DeltaClient.app")
      let currentApp = Bundle.main.bundlePath
      if !self.queue.isSuspended {
        Utils.shell(#"nohup sh -c 'sleep 3; rm -rf \#(currentApp); mv \#(newApp.path) \#(currentApp); open \#(currentApp); open \#(currentApp)' >/dev/null 2>&1 &"#)
        Foundation.exit(0)
      }
    }
  }
  
  // MARK: Helper
  
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
