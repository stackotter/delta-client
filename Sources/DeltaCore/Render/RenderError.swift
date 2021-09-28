//
//  RenderError.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 17/7/21.
//

import Foundation

public enum RenderError: LocalizedError {
  /// Failed to create a metal texture array.
  case failedToCreateTextureArray
  /// Failed to get the Delta Core bundle.
  case failedToGetBundle
  /// Failed to find default.metallib in the bundle.
  case failedToLocateMetallib
  /// Failed to create a metal library from `default.metallib`.
  case failedToCreateMetallib(Error)
  /// Failed to load the shaders from the metallib.
  case failedToLoadShaders
  /// Failed to create the buffers that hold the world uniforms.
  case failedtoCreateWorldUniformBuffers
  /// Failed to create the render pipeline state for the world renderer.
  case failedToCreateWorldRenderPipelineState(Error)
  /// Failed to create the depth stencil state for the world renderer.
  case failedToCreateWorldDepthStencilState
  /// Failed to create the block texture array.
  case failedToCreateBlockTextureArray(Error)
}
