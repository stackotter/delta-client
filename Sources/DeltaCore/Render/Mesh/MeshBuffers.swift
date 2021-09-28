//
//  MeshBuffers.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 19/4/21.
//

import Foundation
import Metal

public struct MeshBuffers {
  public var vertexBuffer: MTLBuffer
  public var indexBuffer: MTLBuffer
  public var uniformsBuffer: MTLBuffer
}
