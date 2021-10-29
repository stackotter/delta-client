import SwiftUI
import ZIPFoundation
import DeltaCore

enum UpdateViewState {
  case selectUpdate
  case performUpdate
}

enum UpdateError: LocalizedError {
  case failedToGetWorkflowRuns
  case failedToGetLatestSuccessfulWorkflowRun(branch: String)
  case failedToGetWorkflowArtifact
  case failedToGetDownloadURL
  case failedToGetDownloadURLFromGitHubReleases
  case failedToGetGitHubAPIResponse(Error)
}

struct UpdateView: View {
  @ObservedObject private var state = StateWrapper<UpdateViewState>(initial: .selectUpdate)
  @ObservedObject private var updater = Updater()
  
  var body: some View {
    switch state.current {
      case .selectUpdate:
        // Gives user a choice of which latest version to update to (stable or unstable)
        VStack {
          Button("Update to latest stable") {
            updater.updateType = .stable
            state.update(to: .performUpdate)
          }.buttonStyle(PrimaryButtonStyle())
          Button("Update to latest unstable") {
            updater.updateType = .unstable
            state.update(to: .performUpdate)
          }.buttonStyle(SecondaryButtonStyle())
        }
        .frame(width: 200)
        
      case .performUpdate:
        // Shows the progress of an update
        VStack(alignment: .leading, spacing: 16) {
          Group {
            if let version = updater.version {
              Text("Updating to \(version)")
            } else {
              Text("Fetching update information")
            }
          }
          .font(.title)
          
          ProgressView(value: updater.fractionCompleted, label: { Text(updater.stepDescription) })
          
          Button("Cancel") {
            state.update(to: .selectUpdate)
          }
          .buttonStyle(SecondaryButtonStyle())
          .frame(width: 200)
          .disabled(!updater.canCancel)
        }
        .frame(maxWidth: 500)
        .onAppear {
          updater.startUpdate()
        }
        .onDisappear {
          updater.cancel()
        }
    }
  }
}
