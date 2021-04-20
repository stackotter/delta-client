//
//  MeshBuffers.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/4/21.
//

import Foundation
import Metal

struct MeshBuffers {
  var vertexBuffer: MTLBuffer
  var indexBuffer: MTLBuffer
  var uniformBuffer: MTLBuffer
}
