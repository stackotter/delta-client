import Collections

extension WorldMeshWorker {
  /// A chunk section mesh creation job.
  struct Job {
    var chunk: Chunk
    var position: ChunkSectionPosition
    var neighbours: ChunkNeighbours
  }
  
  /// Handles queueing jobs and prioritisation.
  struct JobQueue {
    private var jobs: Deque<Job> = []
    private var lock = ReadWriteLock()
    
    /// Creates an empty job queue.
    init() {}
    
    /// Adds a job to the queue.
    mutating func add(_ job: Job) {
      lock.acquireWriteLock()
      defer { lock.unlock() }
      jobs.append(job)
    }
    
    /// Returns the next job to complete.
    mutating func next() -> Job? {
      if !jobs.isEmpty {
        return jobs.removeFirst()
      } else {
        return nil
      }
    }
  }
}
