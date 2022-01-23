import SwiftUI

// MARK: - PixellatedBorder


struct PixellatedBorder: InsettableShape {
  
   // MARK: - UI properties
   
   public var insetAmount: CGFloat = 0
   private let borderCorner: CGFloat = 4


   // MARK: - InsettableShape
   

   func path(in rect: CGRect) -> Path {
     var path = Path()

     path.move(to: CGPoint(x: borderCorner + insetAmount, y: insetAmount))
     path.addLine(to: CGPoint(x: rect.width - borderCorner - insetAmount, y: insetAmount))
     path.move(to: CGPoint(x: rect.width - borderCorner/2 - insetAmount, y: borderCorner + insetAmount))
     path.addLine(to: CGPoint(x: rect.width - borderCorner/2 - insetAmount, y: rect.height - borderCorner - insetAmount))
     path.move(to: CGPoint(x: rect.width - borderCorner - insetAmount, y: rect.height - insetAmount))
     path.addLine(to: CGPoint(x: borderCorner + insetAmount, y: rect.height - insetAmount))
     path.move(to: CGPoint(x: borderCorner/2 + insetAmount, y: rect.height - borderCorner - insetAmount))
     path.addLine(to: CGPoint(x: borderCorner/2 + insetAmount, y: borderCorner + insetAmount))

     return path
   }

   func inset(by amount: CGFloat) -> some InsettableShape {
       var shape = self
       shape.insetAmount += amount
       return shape
   }

 }
