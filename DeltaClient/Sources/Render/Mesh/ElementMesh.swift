//
//  ElementMesh.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/6/21.
//

import Foundation
import Metal
import simd

class ElementMesh: Mesh {
  var vertices: [Vertex] = []
  var indices: [UInt32] = []
  var uniforms: Uniforms
  
  var vertexBuffer: MTLBuffer!
  var indexBuffer: MTLBuffer!
  var uniformBuffer: MTLBuffer!
  
  var hasChanged = false
  
  // maps used to keep track of where elements' vertices are
  private var freeElementIds: [Int] = []
  private var maximumUsedElementId = 0
  private var elementIdToFaceIndices: [Int: [UInt32]] = [:]
  private var faceIndexToElementId: [UInt32: Int] = [:]
  
  init(uniforms: Uniforms) {
    self.uniforms = uniforms
  }
  
  func addBlockModelElement(
    _ element: BlockModelElement,
    at position: Position,
    culling culledFaces: Set<FaceDirection>) -> Int
  {
    let elementId: Int
    if !freeElementIds.isEmpty {
      elementId = freeElementIds.removeLast()
    } else {
      elementId = maximumUsedElementId
      maximumUsedElementId += 1
    }
    
    let translation = MatrixUtil.translationMatrix(simd_float3(
      Float(position.x),
      Float(position.y),
      Float(position.z)))
    let modelMatrix = element.modelMatrix * translation
    
    var faceIndices: [UInt32] = []
    for (direction, face) in element.faces where !culledFaces.contains(direction) {
      let faceIndex = addBlockModelElementFace(face, facing: direction, transformedBy: modelMatrix)
      faceIndices.append(faceIndex)
      faceIndexToElementId[faceIndex] = elementId
    }
    
    elementIdToFaceIndices[elementId] = faceIndices
    return elementId
  }
  
  func addBlockModelElementFace(
    _ face: BlockModelElementFace,
    facing direction: FaceDirection,
    transformedBy transformation: matrix_float4x4) -> UInt32
  {
    let offset = UInt32(vertices.count)
    CubeGeometry.faceWinding.forEach { index in
      indices.append(offset + index)
    }
    
    if let faceVertexPositions = CubeGeometry.faceVertices[direction] {
      faceVertexPositions.enumerated().forEach { uvIndex, vertexPosition in
        let transformedPosition = simd_make_float3(
          simd_float4(vertexPosition, 1) * transformation)
        let vertex = Vertex(
          position: transformedPosition,
          uv: face.uvs[uvIndex],
          light: face.light,
          textureIndex: face.textureIndex,
          tintIndex: face.tintIndex)
        vertices.append(vertex)
      }
    }
    
    let faceIndex = offset / 4
    return faceIndex
  }
  
  func removeBlockModelElement(_ elementId: Int) {
    if let faceIndices = elementIdToFaceIndices[elementId] {
      faceIndices.forEach { faceIndex in
        let lastFaceIndex = vertices.count / 4 - 1
        let isLastFace = faceIndex == lastFaceIndex
        if isLastFace {
          // just remove the face
          vertices.removeLast(4)
        } else {
          // replace face with the last face in vertices
          let lastFaceVertices = vertices.suffix(4)
          let faceBegin = Int(faceIndex * 4)
          let faceEnd = Int(faceIndex * 4 + 4)
          vertices.replaceSubrange(faceBegin..<faceEnd, with: lastFaceVertices)
          
          // update maps
          guard
            let lastFaceElementId = faceIndexToElementId[UInt32(lastFaceIndex)],
            var lastElementFaceIndices = elementIdToFaceIndices[lastFaceElementId]
          else {
            Logger.error(
              "Failed to update face to element and element to face maps when removing face from ElementMesh")
            return
          }
          
          // update elementIdToFaceIndices
          lastElementFaceIndices.removeAll(where: { $0 == UInt32(lastFaceIndex) })
          lastElementFaceIndices.append(faceIndex)
          elementIdToFaceIndices[lastFaceElementId] = lastElementFaceIndices
          
          // update faceIndexToElementId
          faceIndexToElementId.removeValue(forKey: UInt32(lastFaceIndex))
          faceIndexToElementId[faceIndex] = lastFaceElementId
        }
        
        // remove face winding
        indices.removeLast(CubeGeometry.faceWinding.count)
      }
      elementIdToFaceIndices.removeValue(forKey: elementId)
    } else {
      Logger.warn("Cannot remove non-existent element from ElementMesh")
    }
  }
}
