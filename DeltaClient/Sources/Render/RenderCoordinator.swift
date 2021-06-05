//
//  RenderCoordinator.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

import Foundation
import MetalKit


class RenderCoordinator: NSObject, MTKViewDelegate {
  var client: Client
  
  var camera: Camera
  var physicsEngine: PhysicsEngine
  var worldRenderer: WorldRenderer?
  
  var commandQueue: MTLCommandQueue
  var blockArrayTexture: MTLTexture
  
  init(client: Client) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("failed to get metal device")
    }
    
    guard let commandQueue = device.makeCommandQueue() else {
      fatalError("failed to make render command queue")
    }
    
    self.client = client
    self.commandQueue = commandQueue
    
    // setup physics engine (should possibly get the client to do this?)
    physicsEngine = PhysicsEngine(client: client)
    
    // setup camera
    let fovDegrees: Float = 90
    let fovRadians = fovDegrees / 180 * Float.pi
    camera = Camera()
    camera.fovY = fovRadians
    
    // setup textures
    blockArrayTexture = client.managers.textureManager.createArrayTexture(metalDevice: device)
    
    // register server update handler
    super.init()
    
    // create world renderer
    if let world = client.server.world {
      worldRenderer = WorldRenderer(world: world, blockPaletteManager: client.managers.blockPaletteManager, blockArrayTexture: blockArrayTexture)
    }
    
    // register listener for changing worlds
    client.server.registerUpdateHandler(handleClientUpdate(_:))
  }
  
  func handleClientUpdate(_ event: Event) {
    switch event {
      case let event as Server.Event.JoinWorld:
        worldRenderer = WorldRenderer(
          world: event.world,
          blockPaletteManager: client.managers.blockPaletteManager,
          blockArrayTexture: blockArrayTexture)
      default:
        break
    }
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
  
  func getClearColor() -> MTLClearColor {
    return MTLClearColorMake(0.65, 0.8, 1, 1)
  }
  
  func getAspectRatio(of view: MTKView) -> Float {
    return Float(view.drawableSize.width / view.drawableSize.height)
  }
  
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable else {
      fatalError("failed to get current drawable")
    }
    
    guard let device = view.device else {
      fatalError("failed to get metal device (it used to be there)")
    }
    
    guard let view = view as? InteractiveMTKView else {
      fatalError("something has gone seriously wrong, view passed to RenderCoordinator was not interactive")
    }
    
    // update player velocity
    let input = view.inputState
    view.inputState.resetMouseDelta()
    client.server.player.update(with: input)
    
    // physics
    physicsEngine.update()
    
    // update camera parameters
    let aspect = getAspectRatio(of: view)
    camera.aspect = aspect
    camera.position = client.server.player.getEyePositon().vector
    camera.setRotation(playerLook: client.server.player.look)
    
    // render
    if let commandBuffer = commandQueue.makeCommandBuffer() {
      if let renderPassDescriptor = view.currentRenderPassDescriptor {
        renderPassDescriptor.colorAttachments[0].clearColor = getClearColor()
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
          // run renderers
          if let worldRenderer = worldRenderer {
            worldRenderer.draw(device: device, renderEncoder: renderEncoder, camera: camera)
          }
          
          renderEncoder.endEncoding()
          commandBuffer.present(drawable)
          commandBuffer.commit()
        }
      }
    }
  }
}
