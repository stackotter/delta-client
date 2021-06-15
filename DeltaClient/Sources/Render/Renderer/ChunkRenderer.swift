//
//  ChunkRenderer.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 31/5/21.
//

import Foundation
import MetalKit

class ChunkRenderer {
  /// The position of the chunk this renders
  private(set) var chunkPosition: ChunkPosition
  /// The chunk this renders
  private(set) var chunk: Chunk
  /// The chunks neighbouring the chunk this renders
  private(set) var neighbourChunks: [CardinalDirection: Chunk] = [:]
  
  private(set) var requiresPreparing = true
  private(set) var hasCompletedInitialPrepare = true
  
  /// The meshes for the sections of the chunk being rendered, indexed by section Y. Section Y is from 0-15 (inclusive).
  private var sectionMeshes: [Int: ChunkSectionMesh] = [:]
  /// Indices of sections that block updates are currently frozen for
  private var frozenSections: Set<Int> = []
  
  /// A serial queue for safely accessing and modifying `frozenSections`
  private var frozenSectionsAccessQueue = DispatchQueue(label: "dev.stackotter.frozenSectionsAccessQueue")
  /// A serial queue for safely accessing and modifying `sectionMeshes`
  private var sectionMeshesAccessQueue = DispatchQueue(label: "dev.stackotter.sectionMeshesAccessQueue")
  /// A concurrent queue for asynchronously preparing section meshes
  private var meshPreparationQueue = DispatchQueue(
    label: "dev.stackotter.meshPreparationQueue",
    attributes: .concurrent)
  
  private var blockPaletteManager: BlockPaletteManager
  
  var frozenSectionCount: Int {
    frozenSectionsAccessQueue.sync {
      return frozenSections.count
    }
  }
  
  init(
    for chunk: Chunk,
    at position: ChunkPosition,
    withNeighbours neighbours: [CardinalDirection: Chunk],
    with blockPaletteManager: BlockPaletteManager
  ) {
    self.chunkPosition = position
    self.chunk = chunk
    self.neighbourChunks = neighbours
    self.blockPaletteManager = blockPaletteManager
  }
  
  /// Prepare all `Chunk.Section`s in this renderer's `Chunk`
  func prepareAsync() {
    log.debug("Preparing all sections in chunk at \(chunkPosition)")
    
    // set before preparing to prevent getting double prepared
    requiresPreparing = false
    
    let nonEmptySections = chunk.sections.enumerated().filter { _, section in
      return section.blockCount != 0
    }.map { index, _ in
      return index
    }
    
    for (index, sectionIndex) in nonEmptySections.enumerated() {
      prepareSectionAsync(
        at: sectionIndex,
        isLastInitialSection: index == nonEmptySections.count - 1)
    }
  }
  
  /**
   Prepare a mesh for the chunk section specified.
   
   - Parameter isLastInitialSection: If true, `hasCompletedInitialPrepare` is set to true once the mesh is prepared
   */
  private func prepareSectionAsync(at sectionY: Int, isLastInitialSection: Bool = false) {
    let sectionPosition = ChunkSectionPosition(chunkPosition, sectionY: sectionY)
    freezeSection(at: sectionY)
    meshPreparationQueue.async {
      let mesh = ChunkSectionMesh(
        forSectionAt: sectionPosition,
        in: self.chunk,
        withNeighbours: self.neighbourChunks,
        blockPaletteManager: self.blockPaletteManager)
      mesh.prepare()
      self.sectionMeshesAccessQueue.async {
        self.sectionMeshes[sectionY] = mesh
        self.unfreezeSection(at: sectionY)
      }
      if isLastInitialSection {
        log.debug("Completed intial mesh creation for chunk at \(self.chunkPosition)")
        self.hasCompletedInitialPrepare = true
      }
    }
  }
  
  /// Forces all of the chunk's meshes to be re-generated. Existing meshes are not deleted until the new ones are ready.
  func invalidateMeshes() {
    requiresPreparing = true
  }
  
  /// Updates the appropriate section mesh for a section update.
  func handleSectionUpdate(at sectionY: Int) {
    if sectionFrozen(at: sectionY) {
      log.warning("Block update received for frozen section at index \(sectionY) in Chunk at \(chunkPosition)")
      return
    }
    prepareSectionAsync(at: sectionY)
  }
  
  /// Disables block updates for a section
  private func freezeSection(at sectionY: Int) {
    frozenSectionsAccessQueue.sync {
      log.trace("Freezing section at index \(sectionY) in chunk at \(chunkPosition)")
      _ = self.frozenSections.insert(sectionY)
    }
  }
  
  /// Re-enables block updates for a section
  private func unfreezeSection(at sectionY: Int) {
    frozenSectionsAccessQueue.sync {
      log.trace("Unfreezing section at index \(sectionY) in chunk at \(chunkPosition)")
      _ = self.frozenSections.remove(sectionY)
    }
  }
  
  /// Checks whether block updates are enabled for the section at `sectionY`
  func sectionFrozen(at sectionY: Int) -> Bool {
    return frozenSectionsAccessQueue.sync {
      return frozenSections.contains(sectionY)
    }
  }
  
  /// Renders this renderer's chunk
  func render(to encoder: MTLRenderCommandEncoder, with device: MTLDevice, and camera: Camera) {
    sectionMeshesAccessQueue.sync {
      for (sectionY, sectionMesh) in sectionMeshes where !sectionMesh.isEmpty {
        if !camera.isChunkSectionVisible(at: ChunkSectionPosition(chunkPosition, sectionY: sectionY)) {
          continue
        }
        if let buffers = try? sectionMesh.getBuffers(for: device) {
          encoder.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0)
          encoder.setVertexBuffer(buffers.uniformsBuffer, offset: 0, index: 2)
          encoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: buffers.indexBuffer.length / 4,
            indexType: .uint32,
            indexBuffer: buffers.indexBuffer,
            indexBufferOffset: 0)
        } else {
          let sectionPosition = ChunkSectionPosition(chunkPosition, sectionY: sectionY)
          log.error("Failed to prepare buffers for Chunk.Section at \(sectionPosition)")
        }
      }
    }
  }
}
