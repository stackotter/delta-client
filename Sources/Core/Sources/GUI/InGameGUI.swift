import SwiftCPUDetect

public class InGameGUI {
  // TODO: Figure out why anything greater than 252 breaks the protocol. Anything less than 256 should work afaict
  public static let maximumMessageLength = 252

  /// The number of seconds until messages should be hidden from the regular GUI.
  static let messageHideDelay: Double = 10
  /// The maximum number of messages displayed in the regular GUI.
  static let maximumDisplayedMessages = 10
  /// The width of the chat history.
  static let chatHistoryWidth = 330

  /// The system's CPU display name.
  static let cpuName = HWInfo.CPU.name()
  /// The system's CPU architecture.
  static let cpuArch = CpuArchitecture.current()?.rawValue
  /// The system's total memory.
  static let totalMem = (HWInfo.ramAmount() ?? 0) / (1024 * 1024 * 1024)
  /// A string containing information about the system's default GPU.
  static let gpuInfo = GPUDetection.mainMetalGPU()?.infoString()

  public var count: Int = 0

  public init() {}

  public func content(game: Game, state: GUIStateStorage) -> GUIElement {
    GUIElement.stack {
      if let messageInput = state.messageInput {
        GUIElement.list(spacing: 2) {
          GUIElement.list(
            spacing: 2,
            elements: state.chat.messages.map { _ in
              GUIElement.text("message", wrap: true)
            }
          )
          .size(Self.chatHistoryWidth, nil)

          GUIElement.text(messageInput)
        }
        .constraints(.bottom(2), .left(2))
      }

      GUIElement.list(direction: .horizontal, spacing: 2) {
        GUIElement.text("Decrement")
          .padding(10)
          .background(Vec4f(1, 0, 1, 0.5))
          .onClick {
            self.count -= 1
          }

        GUIElement.spacer(width: 10, height: 0)

        GUIElement.text("Increment")
          .padding(10)
          .background(Vec4f(1, 0, 1, 0.5))
          .onClick {
            self.count += 1
          }
      }
        .constraints(.bottom(10), .center)

      GUIElement.text("Count: \(count)")
        .positionInParent(0, 0)
    }
  }
}
