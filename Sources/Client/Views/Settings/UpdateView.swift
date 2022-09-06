import SwiftUI
import ZIPFoundation
import DeltaCore

#if os(macOS)
enum UpdateViewState {
  case selectUpdate
  case performUpdate
}

enum UpdateError: LocalizedError {
  case failedToGetDownloadURL
  case failedToGetDownloadURLFromGitHubReleases
  case failedToGetBranches(Error)
  case failedToGetGitHubAPIResponse(Error)
}

struct UpdateView: View {
  @ObservedObject private var state = StateWrapper<UpdateViewState>(initial: .selectUpdate)
  @ObservedObject private var updater = Updater()

  init() {
    updater.loadUnstableBranches()
  }

  var body: some View {
    switch state.current {
      case .selectUpdate:
        if !updater.hasErrored {
          VStack {
            if !updater.branches.isEmpty {
              Menu {
                ForEach(updater.branches, id: \.self) { branch in
                  Button(branch) {
                    updater.unstableBranch = branch
                  }
                }
              } label: {
                Text("Branch: \(updater.unstableBranch)")
              }
            } else {
              Text("Error: no branches found")
            }

            Button("Update to latest commit") {
              updater.updateType = .unstable
              state.update(to: .performUpdate)
            }
            .buttonStyle(SecondaryButtonStyle())
            Spacer()
          }
          .frame(width: 200)
          .padding(.vertical)
        } else {
          VStack {
            Text("Failed to load update information: \(updater.error?.localizedDescription ?? "No error information")")
            Button("Try again") {
              updater.loadUnstableBranches()
            }.buttonStyle(PrimaryButtonStyle())
          }
          .frame(width: 300)
        }
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
#endif
