import Foundation
import SwiftUI
import Combine

struct StyledSlider: View {
  /// Slider min value
  public let min: Int
  /// Slider max value
  public let max: Int
  /// The slider's title
  public let title: String?
  /// Slider initial value
  private var initialValue: Float?
  /// The slider's frame
  private var sliderFrame: CGSize = .zero
  /// The interactable slider thumb frame
  private var thumbFrame: CGSize = .zero
  /// Borders and text color
  private var themeColor = Color.white
  /// The background color of the interactable slider thumb
  private var thumbFill = Color.clear
  /// The color of the selected (left-handed) track
  private var trackFill = Color.lightGray
  /// The color of the unselected (right-handed) track
  private var trackUnfill = Color.clear

  /// The interactable slide thumb horizontal offset.
  ///
  /// By default, the thumb is centered in the slider. Bounded in [-sliderFrame.width/2, sliderFrame.width/2]
  @State private var dragOffset: CGFloat = .zero
  /// Last saved `dragOffset`
  @State private var lastOffset: CGFloat = .zero
  
  /// Current relative slider value
  private var value: Float {
    return Float((dragOffset + sliderFrame.width/2) / sliderFrame.width) * Float(max - min) + Float(min)
  }
  
  /// Returns asynchronously the slider's value whenever the thumb is moved
  private var onDragChanged: ((Float) -> Void)?
  /// Returns asynchrnously the slider's value when the thumb has finished moving
  private var onDragEnded: ((Float) -> Void)?
  
  public init(
    min: Int,
    max: Int,
    initialValue: Float?,
    title: String? = nil,
    onDragChanged: ((Float) -> Void)? = nil,
    onDragEnded: ((Float) -> Void)? = nil
  ) {
    self.min = min
    self.max = max
    self.initialValue = initialValue
    self.title = title
    self.onDragChanged = onDragChanged
    self.onDragEnded = onDragEnded
  }
  
  var body: some View {
    VStack(spacing: 15) {
      if let title = title {
        HStack {
          Text(title)
            .font(Font.custom(.worksans, size: 15))
            .foregroundColor(themeColor)
          Spacer()
        }
        .frame(width: sliderFrame.width)
      }
      
      HStack(spacing: 10) {
        Text("\(min)")
          .font(Font.custom(.worksans, size: 14))
          .foregroundColor(themeColor)
        
        ZStack(alignment: .center) {
          // Slider
          RoundedRectangle(cornerRadius: 4)
            .stroke(themeColor, lineWidth: 2)
            .frame(width: sliderFrame.width, height: sliderFrame.height, alignment: .leading)
            .background(trackUnfill)
            .background(
              trackFill
                .position(x: dragOffset, y: sliderFrame.height / 2)
                .frame(width: dragOffset + sliderFrame.width/2, height: sliderFrame.height, alignment: .leading)
            )

          // Thumb
          RoundedRectangle(cornerRadius: thumbFrame.height / 2)
            .stroke(themeColor, lineWidth: 2)
            .frame(width: thumbFrame.width, height: thumbFrame.height, alignment: .leading)
            .background(thumbFill)
            .offset(x: dragOffset, y: 0)
            .gesture(
              DragGesture()
                .onChanged({ gesture in
                  dragOffset = computeBoundedOffset(gesture.translation.width + lastOffset)
                  onDragChanged?(value)
                })
                .onEnded({ gesture in
                  lastOffset = computeBoundedOffset(gesture.translation.width + lastOffset)
                  onDragEnded?(value)
                })
            )
        }
        
        Text("\(max)")
          .font(Font.custom(.worksans, size: 14))
          .foregroundColor(themeColor)
      }
    }
    .onChange(of: initialValue) { v in
      dragOffset = sliderFrame.width * CGFloat((v ?? Float(max - min)/2) / Float(max) - 0.5)
      lastOffset = dragOffset
    }
  }
  
  
  /// Sets the slider  frame
  /// - Parameters:
  ///   - width: the slider's width
  ///   - height: the slider's height
  public func frame(width: CGFloat, height: CGFloat) -> StyledSlider {
    var slider = self
    slider.sliderFrame = CGSize(width: width, height: height)
    return slider
  }
  
  /// Sets the slider interactable thumb frame
  /// - Parameters:
  ///   - width: the thumb's width
  ///   - height: the thumb's height
  public func thumbFrame(width: CGFloat, height: CGFloat) -> StyledSlider {
    var slider = self
    slider.thumbFrame = CGSize(width: width, height: height)
    return slider
  }
  
  /// Sets the background color of the interactable slider thumb
  /// - Parameter color: the thumb color
  public func thumbFill(_ color: Color) -> StyledSlider {
    var slider = self
    slider.thumbFill = color
    return slider
  }
  
  /// Sets the slider's main theme color
  /// - Parameter color: the theme color
  public func theme(_ color: Color) -> StyledSlider {
    var slider = self
    slider.themeColor = color
    return slider
  }
  
  /// Sets the background color of the left-handed slider selected track
  /// - Parameter color: the track color
  public func trackFill(_ color: Color) -> StyledSlider {
    var slider = self
    slider.trackFill = color
    return slider
  }
  
  /// Sets the background color of the right-handed slider unselected track
  /// - Parameter color: the track color
  public func trackUnfill(_ color: Color) -> StyledSlider {
    var slider = self
    slider.trackUnfill = color
    return slider
  }
  
  /// Computes the slider thumb bounded absolute offset
  /// - Parameter offset: the absolute offset
  /// - Returns: the bounded absolute offset
  private func computeBoundedOffset(_ offset: CGFloat) -> CGFloat {
    let bounds = (min: -sliderFrame.width/2, max: sliderFrame.width/2)
    return Swift.min(bounds.max, Swift.max(bounds.min, offset))
  }
  
  /// Transforms the relative offset into its absolute counterpart
  /// - Parameter relative: the relative offset
  /// - Returns: the absolute offset
  private func relativeToAbsolute(_ relative: Float) -> CGFloat {
    return sliderFrame.width * CGFloat(relative / Float(min - max) - 0.5)
  }
}
