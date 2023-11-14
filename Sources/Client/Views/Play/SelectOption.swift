import SwiftUI

// TODO: The init is starting to get a bit bloated, perhaps a sign that this
//   view is doing too much, or maybe that some things could be moved to
//   view modifiers? (e.g. the title)
struct SelectOption<Option: Hashable, Row: View, Content: View>: View {
  @State var selectedOption: Option?

  var options: [Option]
  var excludedOptions: [Option]
  var title: String
  var row: (Option) -> Row
  var content: (Option) -> Content
  var cancellationHandler: () -> Void

  init(
    from options: [Option],
    excluding excludedOptions: [Option] = [],
    title: String,
    @ViewBuilder row: @escaping (Option) -> Row,
    andThen content: @escaping (Option) -> Content,
    cancellationHandler: @escaping () -> Void
  ) {
    self.options = options
    self.excludedOptions = excludedOptions
    self.title = title
    self.row = row
    self.content = content
    self.cancellationHandler = cancellationHandler
  }

  var body: some View {
    if let selectedOption = selectedOption {
      content(selectedOption)
    } else {
      VStack {
        Text(title)
          .font(.title)

        VStack {
          Divider()
          ForEach(options, id: \.self) { option in
            HStack {
              row(option)

              Spacer()

              Image(systemName: "chevron.right")
            }
            .contentShape(Rectangle())
            .onTapGesture {
              guard !excludedOptions.contains(option) else {
                return
              }
              selectedOption = option
            }
            .padding(.top, 0.3)
            .foregroundColor(excludedOptions.contains(option) ? .gray : .primary)

            Divider()
          }

          Button("Cancel", action: cancellationHandler)
            .buttonStyle(SecondaryButtonStyle())
            .frame(width: 150)
        }
        .padding(.bottom, 10)
      }
      .frame(width: 300)
    }
  }
}
