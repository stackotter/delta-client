import SwiftUI

struct PixellatedBorder: InsettableShape {
  public var insetAmount: CGFloat = 0
  
  private let borderCorner: CGFloat = 4

  func path(in rect: CGRect) -> Path {
    var path = Path()

    // Top
    path.move(to: CGPoint(x: borderCorner + insetAmount, y: borderCorner / 2 + insetAmount))
    path.addLine(to: CGPoint(x: rect.width - borderCorner - insetAmount, y: borderCorner / 2 + insetAmount))

    // Right
    path.move(to: CGPoint(x: rect.width - borderCorner / 2 - insetAmount, y: borderCorner + insetAmount))
    path.addLine(to: CGPoint(x: rect.width - borderCorner/2 - insetAmount, y: rect.height - borderCorner - insetAmount))

    // Bottom
    path.move(to: CGPoint(x: rect.width - borderCorner - insetAmount, y: rect.height - borderCorner / 2 - insetAmount))
    path.addLine(to: CGPoint(x: borderCorner + insetAmount, y: rect.height - borderCorner / 2 - insetAmount))

    // Left
    path.move(to: CGPoint(x: borderCorner / 2 + insetAmount, y: rect.height - borderCorner - insetAmount))
    path.addLine(to: CGPoint(x: borderCorner / 2 + insetAmount, y: borderCorner + insetAmount))

    return path
  }
  
  func inset(by amount: CGFloat) -> some InsettableShape {
    var border = self
    border.insetAmount += amount
    return border
  }
}
