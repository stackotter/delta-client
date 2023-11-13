import SwiftUI
import DeltaCore

struct SelectAccountAndThen<Content: View>: View {
  @EnvironmentObject var managedConfig: ManagedConfig

  var excludedAccounts: [Account]
  var content: (Account) -> Content
  var cancellationHandler: () -> Void

  init(
    excluding excludedAccounts: [Account] = [],
    @ViewBuilder content: @escaping (Account) -> Content,
    cancellationHandler: @escaping () -> Void
  ) {
    self.excludedAccounts = excludedAccounts
    self.content = content
    self.cancellationHandler = cancellationHandler
  }

  var body: some View {
    SelectOption(
      from: managedConfig.config.orderedAccounts,
      excluding: excludedAccounts,
      title: "Select an account"
    ) { account in
      HStack {
        Text(account.username)
        Text(account.type)
          .foregroundColor(.gray)
      }
    } andThen: { account in
      content(account)
    } cancellationHandler: {
      cancellationHandler()
    }
  }
}
