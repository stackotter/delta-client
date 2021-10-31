import SwiftUI

// MARK: - PopupBorder


struct PopupBorder: InsettableShape {
  
  
  // MARK: - Properties.UI
  
  public var insetAmount: CGFloat = 0
  private let borderCorner: CGFloat = 4

  
  // MARK: - Methods.InsettableShape
  
  
  func path(in rect: CGRect) -> Path {
    var path = Path()
    
    path.move(to: CGPoint(x: borderCorner + insetAmount, y: insetAmount))
    path.addLine(to: CGPoint(x: rect.width - borderCorner - insetAmount, y: insetAmount))
    path.addLine(to: CGPoint(x: rect.width - borderCorner - insetAmount, y: borderCorner + insetAmount))
    path.addLine(to: CGPoint(x: rect.width - insetAmount, y: borderCorner + insetAmount))
    path.addLine(to: CGPoint(x: rect.width - insetAmount, y: rect.height - borderCorner - insetAmount))
    path.addLine(to: CGPoint(x: rect.width - borderCorner - insetAmount, y: rect.height - borderCorner - insetAmount))
    path.addLine(to: CGPoint(x: rect.width - borderCorner - insetAmount, y: rect.height - insetAmount))
    path.addLine(to: CGPoint(x: borderCorner + insetAmount, y: rect.height - insetAmount))
    path.addLine(to: CGPoint(x: borderCorner + insetAmount, y: rect.height - borderCorner - insetAmount))
    path.addLine(to: CGPoint(x: insetAmount, y: rect.height - borderCorner - insetAmount))
    path.addLine(to: CGPoint(x: insetAmount, y: borderCorner + insetAmount))
    path.addLine(to: CGPoint(x: borderCorner + insetAmount, y: borderCorner + insetAmount))
    path.closeSubpath()
    
    return path
  }
  
  func inset(by amount: CGFloat) -> some InsettableShape {
      var shape = self
      shape.insetAmount += amount
      return shape
  }
  
}
