//
//  VideoConfig.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 10/7/21.
//

import Foundation

/// Rendering related config.
public struct VideoConfig: Codable {
  /// The distance at which chunks should no longer be rendered.
  public var renderDistance: Int
  /// The vertical fov to render with in degrees.
  public var fov: Int
  
  /// Creates the default rendering config
  public init() {
    renderDistance = 10
    fov = 90
  }
}
