import SwiftUI
import ZIPFoundation
import DeltaCore

#if os(macOS)
enum UpdateViewState {
  case loadingBranches
  case selectBranch(branches: [String])
  case updating
}

struct UpdateView: View {
  @EnvironmentObject var appState: StateWrapper<AppState>
  @EnvironmentObject var modal: Modal
  @Environment(\.storage) var storage: StorageDirectory

  @ObservedObject var state = StateWrapper<UpdateViewState>(initial: .loadingBranches)
  @ObservedObject var progress = TaskProgress<Updater.UpdateStep>()

  @State var branch: String?
  @State var updateVersion: String?

  var task: Task<(), Never>?

  init() {}

  var body: some View {
    switch state.current {
      case .loadingBranches:
        Text("Loading branches...")
          .onAppear {
            Task {
              do {
                let branches = try Updater.getBranches().map(\.name)
                state.update(to: .selectBranch(branches: branches))
              } catch {
                modal.error(error) {
                  appState.update(to: .serverList)
                }
              }
            }
          }
      case let .selectBranch(branches):
        VStack {
          Menu {
            ForEach(branches, id: \.self) { branch in
              Button(branch) {
                self.branch = branch
              }
            }
          } label: {
            if let branch = branch {
              Text("Branch: \(branch)")
            } else {
              Text("Select a branch")
            }
          }

          if let branch = branch {
            Button("Update to latest commit") {
              state.update(to: .updating)
              Task {
                do {
                  let download = try Updater.getDownload(for: .nightly(branch: branch))
                  updateVersion = download.version
                  try await Updater.performUpdate(
                    download: download,
                    isNightly: true,
                    storage: storage,
                    progress: progress
                  )
                } catch {
                  modal.error(error) {
                    appState.update(to: .serverList)
                  }
                }
              }
            }
            .buttonStyle(SecondaryButtonStyle())
          } else {
            Button("Update to latest commit") {}
              .disabled(true)
              .buttonStyle(SecondaryButtonStyle())
          }
        }
        .frame(width: 200)
        .padding(.vertical)
      case .updating:
        // Shows the progress of an update
        VStack(alignment: .leading, spacing: 16) {
          Group {
            if let version = updateVersion {
              Text("Updating to \(version)")
            } else {
              Text("Fetching update information")
            }
          }
          .font(.title)

          ProgressView(value: progress.progress) {
            Text(progress.message)
          }

          Button("Cancel") {
            state.update(to: .loadingBranches)
          }
          .buttonStyle(SecondaryButtonStyle())
          .frame(width: 200)
        }
        .frame(maxWidth: 500)
        .onDisappear {
          task?.cancel()
        }
    }
  }
}
#endif
