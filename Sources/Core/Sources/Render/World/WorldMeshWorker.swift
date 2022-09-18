import Foundation
import Atomics
import Metal

/// A multi-threaded worker that creates and updates the world's meshes. Completely threadsafe.
public class WorldMeshWorker {
  // MARK: Public properties

  /// The number of jobs currently queued.
  public var jobCount: Int {
    jobQueue.count
  }

  // MARK: Private properties

  /// World that chunks are in.
  private var world: World
  /// Resources to prepare chunks with.
  private let resources: ResourcePack.Resources

  /// A lock used to make the worker threadsafe.
  private var lock = ReadWriteLock()

  /// Meshes that the worker has created or updated and the ``WorldRenderer`` hasn't taken back yet.
  private var updatedMeshes: [ChunkSectionPosition: ChunkSectionMesh] = [:]

  /// Mesh creation jobs.
  private var jobQueue = JobQueue()
  /// Serial dispatch queue for executing jobs on.
  private var executionQueue = DispatchQueue(label: "dev.stackotter.delta-client.WorldMeshWorker", attributes: [.concurrent])
  /// Whether the execution loop is currently running or not.
  private var executingThreadsCount = ManagedAtomic<Int>(0)
  /// The maximum number of execution loops allowed to run at once (for performance reasons).
  private let maxExecutingThreadsCount = 1 // TODO: Scale max threads and executionQueue qos with size of job queue

  // MARK: Init

  /// Creates a new world mesh worker.
  public init(world: World, resources: ResourcePack.Resources) {
    self.world = world
    self.resources = resources
  }

  // MARK: Public methods

  /// Creates a new mesh for the specified chunk section.
  public func createMeshAsync(
    at position: ChunkSectionPosition,
    in chunk: Chunk,
    neighbours: ChunkNeighbours
  ) {
    let job = Job(
      chunk: chunk,
      position: position,
      neighbours: neighbours)
    jobQueue.add(job)
    startExecutionLoop()
  }

  /// Gets the meshes that have been updated since the last call to this function.
  /// - Returns: The updated meshes and their positions.
  public func getUpdatedMeshes() -> [ChunkSectionPosition: ChunkSectionMesh] {
    lock.acquireWriteLock()

    defer {
      updatedMeshes = [:]
      lock.unlock()
    }

    return updatedMeshes
  }

  // MARK: Private methods

  /// Starts an asynchronous loop that executes all jobs on the queue until there are none left.
  private func startExecutionLoop() {
    if executingThreadsCount.load(ordering: .relaxed) >= maxExecutingThreadsCount {
      return
    }

    executingThreadsCount.wrappingIncrement(ordering: .relaxed)

    executionQueue.async {
      while true {
        let jobWasExecuted = self.executeNextJob()

        // If no job was executed, the job queue is empty and this execution loop can stop
        if !jobWasExecuted {
          if self.executingThreadsCount.wrappingDecrementThenLoad(ordering: .relaxed) < 0 {
            log.warning("Error in WorldMeshWorker thread management, number of executing threads is below 0")
          }
          return
        }
      }
    }
  }

  /// Executes the next job.
  /// - Returns: `false` if there were no jobs to execute.
  private func executeNextJob() -> Bool {
    guard let job = jobQueue.next() else {
      return false
    }

    var affectedChunks: [Chunk] = []

    for position in WorldMesh.chunksRequiredToPrepare(chunkAt: job.position.chunk) {
      if let chunk = world.chunk(at: position) {
        chunk.acquireReadLock()
        affectedChunks.append(chunk)
      }
    }

    let meshBuilder = ChunkSectionMeshBuilder(
      forSectionAt: job.position,
      in: job.chunk,
      withNeighbours: job.neighbours,
      world: world,
      resources: resources
    )

    // TODO: implement buffer recycling
    let mesh = meshBuilder.build()

    for chunk in affectedChunks {
      chunk.unlock()
    }

    lock.acquireWriteLock()
    updatedMeshes[job.position] = mesh
    lock.unlock()

    return true
  }
}
