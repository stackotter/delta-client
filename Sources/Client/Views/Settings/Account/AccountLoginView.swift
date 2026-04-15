import SwiftUI
import DeltaCore

enum LoginViewState {
  case chooseAccountType
  case loginMicrosoft
  case loginMojang
  case loginOffline
}

struct AccountLoginView: EditorView {
  typealias Item = Account
  
  @State var state: LoginViewState = .chooseAccountType
  
  let completionHandler: (Item) -> Void
  let cancelationHandler: (() -> Void)?
  
  /// Ignores `item` because this view is only ever used for logging into account not editing them.
  init(_ item: Item? = nil, completion: @escaping (Item) -> Void, cancelation: (() -> Void)?) {
    completionHandler = completion
    cancelationHandler = cancelation
  }
  
  var body: some View {
    switch state {
      case .chooseAccountType:
        VStack {
          Text("Choose account type")
          
          Button("Microsoft") {
            state = .loginMicrosoft
          }.buttonStyle(PrimaryButtonStyle())
          
          Button("Mojang") {
            state = .loginMojang
          }.buttonStyle(PrimaryButtonStyle())
          
          Button("Offline") {
            state = .loginOffline
          }.buttonStyle(PrimaryButtonStyle())
          
          Spacer().frame(height: 32)
          
          Button("Cancel") {
            cancelationHandler?()
          }.buttonStyle(SecondaryButtonStyle())
        }
        .navigationTitle("Account Login")
        #if !os(iOS)
        .onExitCommand {
          cancelationHandler?()
        }
        #endif
        #if !os(tvOS)
        .frame(width: 200)
        #endif
      case .loginMicrosoft:
        MicrosoftLoginView(loginViewState: $state, completionHandler: completionHandler)
      case .loginMojang:
        MojangLoginView(loginViewState: $state, completionHandler: completionHandler)
      case .loginOffline:
        OfflineLoginView(loginViewState: $state, completionHandler: completionHandler)
    }
  }
}
