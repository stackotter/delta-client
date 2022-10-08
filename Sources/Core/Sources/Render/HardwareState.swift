import MetalKit

extension RenderCoordinator {
  /// The state of user's GPU hardware.
  struct HardwareState {
    
    /// The device used to render.
    private var device: MTLDevice
    
    /// Initialises hardware state based on data obtained from device used in rendering.
    /// - Parameter device: MTLDevice used to render
    init(for device: MTLDevice) {
      self.device = device
      
      if #available(macOS 13, iOS 16, *) {
        self.supportsMetal3 = self.device.supportsFamily(.metal3)
      }
      else {
        self.supportsMetal3 = false
      }
      
      self.hasUnifiedMemory = self.device.hasUnifiedMemory
    }
    
    /// Flag indicating support for Metal 3 feature set.
    public let supportsMetal3: Bool
    
    /// Flag indicating whether device has unified memory.
    public let hasUnifiedMemory: Bool
  }
}
