import Collections

extension WorldMeshWorker {
  /// A chunk section mesh creation job.
  struct Job {
    /// The chunk that the section is in.
    var chunk: Chunk
    /// The position of the section to prepare.
    var position: ChunkSectionPosition
    /// The neighbouring chunks of ``chunk``.
    var neighbours: ChunkNeighbours
  }

  /// Handles queueing jobs and prioritisation. Completely threadsafe.
  struct JobQueue {
    /// The number of jobs currently in the queue.
    public var count: Int {
      lock.acquireReadLock()
      defer { lock.unlock() }
      return jobs.count
    }

    /// The queue of current jobs.
    private var jobs: Deque<Job> = []
    /// A lock used to make the job queue threadsafe.
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
      lock.acquireWriteLock()
      defer { lock.unlock() }
      if !jobs.isEmpty {
        return jobs.removeFirst()
      } else {
        return nil
      }
    }
  }
}
