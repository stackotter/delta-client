import Foundation
import SwiftUI

struct StyledDropdown: View {
 
  /// The dropdown main title
  public let title: String?
  /// The dropdown empty state placeholder
  public let placeholder: String?
  /// The pickable dropdown options, displayed when the dropdown is expanded
  public let pickables: [String]
  /// The dropdown border and main text color
  private var mainColor = Color.white
  /// The dropdown's placeholder and secondary color
  private var secondaryColor = Color.white.opacity(0.6)
  /// The dropdown's frame
  private var dFrame: CGSize = .zero
  /// Whether the dropdown onAppear callback has been already called or not
  @State private var viewAppeared: Bool = false
  /// Whether `pickables` are shown or not
  @Binding private var isExpanded: Bool

  
  /// Returns asynchrnously the pickable index on selection
  private let onSelection: ((Int) -> Void)?
  
  
  public init(
    title: String?,
    placeholder: String? = nil,
    isExpanded: Binding<Bool>,
    pickables: [String],
    onSelection: ((Int) -> Void)?
  ) {
    self.title = title
    self.placeholder = placeholder
    self.pickables = pickables
    self.onSelection = onSelection
    // TODO: Users of dropdown shouldn't have to pass in isExpanded, that should just be an internal detail
    self._isExpanded = isExpanded
  }
  
  
  var body: some View {
    let borderWidth: CGFloat = 2
    
    VStack {
      // Static rect
      HStack {
        // Placeholder
        buildText(title ?? placeholder ?? "", color: title != nil ? mainColor : secondaryColor)
        Spacer()
        // Icon
        Image(systemName: "chevron.down")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .foregroundColor(mainColor)
          .frame(width: dFrame.height*0.425, height: dFrame.height*0.425)
          .offset(y: 1)
          .rotationEffect(isExpanded ? Angle.degrees(180) : .zero)
          .animation(viewAppeared ? .linear(duration: 0.2) : nil)
      }
      .frame(width: dFrame.width, height: dFrame.height)
      .background(Color.clear)
      .contentShape(Rectangle())
      .onTapGesture { isExpanded.toggle() }
      
      // Pickables
      if isExpanded {
        Divider().background(secondaryColor)
        ScrollView(showsIndicators: false) {
          ForEach(pickables.indices, id: \.self) { i in
            VStack {
              HStack {
                buildText(pickables[i], color: mainColor)
                Spacer()
              }
              Divider()
                .background(i == pickables.count - 1 ? Color.clear : secondaryColor)
            }
            .frame(width: dFrame.width, height: dFrame.height - 2*borderWidth)
            .contentShape(Rectangle())
            .onTapGesture {
              onSelection?(i)
            }
          }
        }
        .frame(maxHeight: dFrame.height * 5)
      }
    }
    .padding(.horizontal, dFrame.width * 0.075)
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .stroke(mainColor, lineWidth: borderWidth)
    )
    .frame(width: dFrame.width)
    .animation(viewAppeared ? .easeInOut(duration: 0.2) : nil)
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { viewAppeared = true }
    }
  }
  
  
  /// Builds a pre-styled text element
  ///
  /// - Parameters:
  ///   - text: the element's text
  ///   - color: the element's text color
  @ViewBuilder private func buildText(_ text: String, color: Color) -> some View {
    Text(text)
      .foregroundColor(color)
      .font(Font.custom(.worksans, size: dFrame.height*0.43))
  }
  
  /// Sets the dropdown secondary
  ///
  /// - Parameter color: the secondary color
  public func border(_ color: Color) -> StyledDropdown {
    var dropdown = self
    dropdown.secondaryColor = color
    return dropdown
  }
  
  /// Sets the dropdown frame
  ///
  /// - Parameters:
  ///   - width: the dropdown width
  ///   - height: the dropdown height
  public func dropdownFrame(width: CGFloat, height: CGFloat) -> StyledDropdown {
    var dropdown = self
    dropdown.dFrame = CGSize(width: width, height: height)
    return dropdown
  }
}
