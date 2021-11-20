import Collections

extension WorldMeshWorker {
  /// The priority of mesh creation job.
  public enum JobPriority: CaseIterable {
    /// The highest priority is updates affecting only a few blocks, they are most likely user initiated.
    case blockUpdate
    /// The second highest priority is updates the replace existing chunk sections.
    case wholeChunkSectionUpdate
    /// The lowest priority is loading chunks.
    case chunkLoad
  }
  
  /// A chunk section mesh creation job.
  struct Job {
    var chunk: Chunk
    var position: ChunkSectionPosition
    var neighbours: ChunkNeighbours
  }
  
  /// Handles queueing jobs and prioritisation.
  struct JobQueue {
    private var chunkLoadJobs: Deque<Job> = []
    private var wholeChunkSectionUpdateJobs: Deque<Job> = []
    private var blockUpdateJobs: Deque<Job> = []
    
    private var lock = ReadWriteLock()
    
    /// Creates an empty job queue.
    init() {}
    
    /// Adds a job to the correct queue.
    mutating func add(_ job: Job, priority: JobPriority) {
      withMutableQueue(priority: priority) { queue in
        queue.append(job)
      }
    }
    
    /// Returns the next job to complete.
    mutating func next() -> Job? {
      for priority in JobPriority.allCases {
        var job: Job? = nil
        withMutableQueue(priority: priority) { queue in
          if !queue.isEmpty {
            job = queue.removeFirst()
          }
        }
        if let job = job {
          return job
        }
      }
      return nil
    }
    
//    private func nonEmptyQueues() -> [JobPriority] {
//      for priority
//    }
    
    private func withQueue(priority: JobPriority, action: (Deque<Job>) -> Void) {
      lock.acquireReadLock()
      defer { lock.unlock() }
      switch priority {
        case .chunkLoad:
          action(chunkLoadJobs)
        case .wholeChunkSectionUpdate:
          action(wholeChunkSectionUpdateJobs)
        case .blockUpdate:
          action(blockUpdateJobs)
      }
    }
    
    private mutating func withMutableQueue(priority: JobPriority, action: (inout Deque<Job>) -> Void) {
      lock.acquireWriteLock()
      defer { lock.unlock() }
      switch priority {
        case .chunkLoad:
          action(&chunkLoadJobs)
        case .wholeChunkSectionUpdate:
          action(&wholeChunkSectionUpdateJobs)
        case .blockUpdate:
          action(&blockUpdateJobs)
      }
    }
  }
}
