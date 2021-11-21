import Foundation
import Concurrency
import Metal

/// A multi-threaded worker that creates and updates the world's meshes.
public class WorldMeshWorker {
  // MARK: Public properties
  
  /// World that chunks are in.
  public var world: World
  /// Resources to prepare chunks with.
  public var resources: ResourcePack.Resources
  
  // MARK: Private properties
  
  /// Meshes that the worker has created or updated and the `WorldRenderer` hasn't taken back yet.
  private var updatedMeshes: [ChunkSectionPosition: ChunkSectionMesh] = [:]
  /// A lock to manage reading and writing of `updatedMeshes`.
  private var updatedMeshesLock = ReadWriteLock()
  
  /// Mesh creation jobs.
  private var jobQueue = JobQueue()
  /// Serial dispatch queue for executing jobs on.
  private var executionQueue = DispatchQueue(label: "dev.stackotter.delta-client.WorldMeshWorker", attributes: [.concurrent])
  /// Whether the execution loop is currently running or not.
  private var executingThreadsCount = AtomicInt(initialValue: 0)
  /// The maximum number of execution loops allowed to run at once (for performance reasons).
  private let maxExecutingThreadsCount = 2
  
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
  
  /// Returns meshes that have been updated since the last call to this function.
  public func getUpdatedMeshes() -> [ChunkSectionPosition: ChunkSectionMesh] {
    updatedMeshesLock.acquireWriteLock()
    defer { updatedMeshesLock.unlock() }
    let meshes = updatedMeshes
    updatedMeshes = [:]
    return meshes
  }
  
  // MARK: Private methods
  
  /// Starts an asynchronous loop that executes all jobs on the queue until there are none left.
  private func startExecutionLoop() {
    log.debug("Attempting to start execution loop")
    
    if executingThreadsCount.value >= maxExecutingThreadsCount {
      return
    }
    
    let count = executingThreadsCount.incrementAndGet()
    
    log.debug("Starting WorldMeshWorker execution thread number \(count)")
    
    executionQueue.async {
      var stopwatch = Stopwatch(mode: .summary, name: "Execution loop \(count)")
      defer {
        stopwatch.summary()
        log.debug("Stopping WorldMeshWorker execution thread number \(count)")
      }
      
      while true {
        stopwatch.startMeasurement("executeNextJob")
        let jobWasExecuted = self.executeNextJob()
        stopwatch.stopMeasurement("executeNextJob")
        
        // If no job was executed, the job queue is empty and this execution loop can stop
        if !jobWasExecuted {
          if self.executingThreadsCount.decrementAndGet() < 0 {
            log.warning("Error in WorldMeshWorker thread management, number of executing threads is below 0 (whoops)")
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
    
    let meshBuilder = ChunkSectionMeshBuilder(
      forSectionAt: job.position,
      in: job.chunk,
      withNeighbours: job.neighbours,
      world: world,
      resources: resources)
    // TODO: implement buffer recycling
    let mesh = meshBuilder.build()
    
    updatedMeshesLock.acquireWriteLock()
    updatedMeshes[job.position] = mesh
    updatedMeshesLock.unlock()
    
    return true
  }
}
