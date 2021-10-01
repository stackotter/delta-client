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
  public var hasCompletedInitialPrepare = true
  
  /// The meshes for the sections of the chunk being rendered, indexed by section Y. Section Y is from 0-15 (inclusive).
  private var sectionMeshes: [Int: Mesh] = [:]
  /// Indices of sections that block updates are currently frozen for.
  private var frozenSections: Set<Int> = []
  
  /// A serial queue for safely accessing and modifying `frozenSections`.
  private var frozenSectionsAccessQueue = DispatchQueue(label: "dev.stackotter.frozenSectionsAccessQueue")
  /// A serial queue for safely accessing and modifying `sectionMeshes`.
  private var sectionMeshesAccessQueue = DispatchQueue(label: "dev.stackotter.sectionMeshesAccessQueue")
  /// A concurrent queue for asynchronously preparing section meshes.
  private var meshPreparationQueue = DispatchQueue(label: "dev.stackotter.meshPreparationQueue")
  
  /// The resources to use when rendering chunks.
  private let resources: ResourcePack.Resources
  
  var frozenSectionCount: Int {
    frozenSectionsAccessQueue.sync {
      return frozenSections.count
    }
  }
  
  init(
    for chunk: Chunk,
    at position: ChunkPosition,
    withNeighbours neighbours: [CardinalDirection: Chunk],
    with resources: ResourcePack.Resources
  ) {
    self.chunkPosition = position
    self.chunk = chunk
    self.neighbourChunks = neighbours
    self.resources = resources
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
    
    for sectionIndex in nonEmptySections {
      prepareSectionAsync(at: sectionIndex)
    }
    
    meshPreparationQueue.async {
      self.hasCompletedInitialPrepare = true
    }
  }
  
  /// Prepare a mesh for the chunk section specified.
  private func prepareSectionAsync(at sectionY: Int) {
    let sectionPosition = ChunkSectionPosition(chunkPosition, sectionY: sectionY)
    freezeSection(at: sectionY)
    
    meshPreparationQueue.async {
      let builder = ChunkSectionMeshBuilder(
        forSectionAt: sectionPosition,
        in: self.chunk,
        withNeighbours: self.neighbourChunks,
        resources: self.resources)
      let mesh = builder.build()
      
      self.sectionMeshesAccessQueue.async {
        if let mesh = mesh {
          self.sectionMeshes[sectionY] = mesh
          self.unfreezeSection(at: sectionY)
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
      sectionMeshes.mutatingEach { sectionY, mesh in
        // Don't need to check if mesh is empty because the mesh builder never returns empty meshes
        
        let sectionPosition = ChunkSectionPosition(chunkPosition, sectionY: sectionY)
        if !camera.isChunkSectionVisible(at: sectionPosition) {
          return
        }

        do {
          try mesh.render(into: encoder, with: device, commandQueue: commandQueue)
        } catch {
          log.error("Failed to render chunk section at \(sectionPosition); \(error)")
        }
      }
    }
  }
}
