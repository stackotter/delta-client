import Collections

/// A `WorldMeshWorker` job.
protocol WorldMeshWorkerJob {}

extension WorldMeshWorker {
  typealias Job = WorldMeshWorkerJob
  
  /// The priority of mesh creation job.
  public enum JobPriority: CaseIterable {
    /// The highest priority is loading chunks.
    case chunkLoad
    /// The second highest priority is updates affecting whole chunk sections.
    case chunkSectionUpdate
    /// The third highest priority is updates affecting only a few blocks.
    case blockUpdate
  }
  
  /// A chunk section mesh creation job.
  struct SingleJob: Job {
    var chunk: Chunk
    var position: ChunkSectionPosition
    var neighbours: ChunkNeighbours
  }
  
  /// Multiple jobs that must be completed at the same time (to avoid visual glitches).
  struct JobGroup: Job {
    var jobs: [SingleJob] = []
  }
  
  /// Handles queueing jobs and prioritisation.
  struct JobQueue {
    /// The queues containing jobs of each priority.
    var jobs: [JobPriority: Deque<Job>] = [
      .chunkLoad: [],
      .chunkSectionUpdate: [],
      .blockUpdate: []]
    
    var lock = ReadWriteLock()
    
    /// Adds a job to the correct queue.
    mutating func add(_ job: Job, priority: JobPriority) {
      lock.acquireWriteLock()
      jobs[priority]!.append(job)
      lock.unlock()
    }
    
    /// Returns the next job to complete.
    mutating func next() -> Job? {
      lock.acquireWriteLock()
      defer {
        lock.unlock()
      }
      for priority in JobPriority.allCases {
        if let queue = jobs[priority], !queue.isEmpty {
          return jobs[priority]!.removeFirst()
        }
      }
      return nil
    }
  }
}
