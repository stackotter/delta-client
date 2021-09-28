import Foundation
import MetalKit

class ChunkRenderer {
  /// The position of the chunk this renders.
  public var chunkPosition: ChunkPosition
  /// The chunk this renders.
  public var chunk: Chunk
  /// The chunks neighbouring the chunk this renders.
  public var neighbourChunks: [CardinalDirection: Chunk] = [:]
  
  public var requiresPreparing = true
  public var hasCompletedInitialPrepare: Bool {
    return sectionMeshesAccessQueue.sync {
      numSectionsPreparing == 0
    }
  }
  
  /// The meshes for the sections of the chunk being rendered, indexed by section Y. Section Y is from 0-15 (inclusive).
  private var sectionMeshes: [Int: ChunkSectionMesh] = [:]
  /// Indices of sections that block updates are currently frozen for.
  private var frozenSections: Set<Int> = []
  
  /// A serial queue for safely accessing and modifying `frozenSections`.
  private var frozenSectionsAccessQueue = DispatchQueue(label: "dev.stackotter.frozenSectionsAccessQueue")
  /// A serial queue for safely accessing and modifying `sectionMeshes`.
  private var sectionMeshesAccessQueue = DispatchQueue(label: "dev.stackotter.sectionMeshesAccessQueue")
  /// A concurrent queue for asynchronously preparing section meshes.
  private var meshPreparationQueue = DispatchQueue(
    label: "dev.stackotter.meshPreparationQueue")
  
  /// The resource pack to render chunks with.
  private let resourcePack: ResourcePack
  
  private var numSectionsPreparing = 0
  
  var frozenSectionCount: Int {
    frozenSectionsAccessQueue.sync {
      return frozenSections.count
    }
  }
  
  init(
    for chunk: Chunk,
    at position: ChunkPosition,
    withNeighbours neighbours: [CardinalDirection: Chunk],
    with resourcePack: ResourcePack
  ) {
    self.chunkPosition = position
    self.chunk = chunk
    self.neighbourChunks = neighbours
    self.resourcePack = resourcePack
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
    
    numSectionsPreparing = nonEmptySections.count
    
    for sectionIndex in nonEmptySections {
      prepareSectionAsync(at: sectionIndex, isInitialPrepare: true)
    }
  }
  
  /**
   Prepare a mesh for the chunk section specified.
   
   - Parameter isLastInitialSection: If true, `hasCompletedInitialPrepare` is set to true once the mesh is prepared
   */
  private func prepareSectionAsync(at sectionY: Int, isInitialPrepare: Bool = false) {
    let sectionPosition = ChunkSectionPosition(chunkPosition, sectionY: sectionY)
    freezeSection(at: sectionY)
    meshPreparationQueue.async {
      let mesh = ChunkSectionMesh(
        forSectionAt: sectionPosition,
        in: self.chunk,
        withNeighbours: self.neighbourChunks,
        resourcePack: self.resourcePack)
      mesh.prepare()
      self.sectionMeshesAccessQueue.async {
        self.sectionMeshes[sectionY] = mesh
        self.unfreezeSection(at: sectionY)
        if isInitialPrepare {
          self.numSectionsPreparing -= 1
        }
      }
    }
  }
  
  /// Forces all of the chunk's meshes to be re-generated. Existing meshes are not deleted until the new ones are ready.
  func invalidateMeshes() {
    requiresPreparing = true
  }
  
  /// Updates the appropriate section mesh for a section update.
  func handleSectionUpdate(at sectionY: Int) {
    if !hasCompletedInitialPrepare {
      return
    }
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
  func render(to encoder: MTLRenderCommandEncoder, with device: MTLDevice, and camera: Camera, commandQueue: MTLCommandQueue) {
    sectionMeshesAccessQueue.sync {
      for (sectionY, sectionMesh) in sectionMeshes where !sectionMesh.isEmpty {
        if !camera.isChunkSectionVisible(at: ChunkSectionPosition(chunkPosition, sectionY: sectionY)) {
          continue
        }

        if let buffers = try? sectionMesh.getBuffers(for: device, commandQueue: commandQueue) {
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
