# Debugging deadlocks 

The more high performance parts of Delta Client use locks to ensure threadsafety (instead of higher
level and slower concepts such as dispatch queues). This is all well and good until a subtle bug
causes a deadlock and ruins your day. This document will hopefully help you find the cause faster.

## The basics

Where applicable, many methods have an `acquireLock` parameter to allow callers to have more control
over how locking occurs. The most common use case for this is calling a locking function from within
another locking function. If either of the functions requires a write lock, you're in trouble, and
the easiest way to avoid this issue is to call the inner function with `acquireLock: false`. Make
sure that the outer function acquires a lock that is at least as permissive as the inner function
requires. For example, if the inner function normally acquires a write lock, the outer function must
acquire a write lock too.

## Pay attention to lock levels

Often locks are arranged into levels, `World` has `terrainLock` for accessing chunks from the chunk
storage, and then `Chunk` has `lock` for accessing its stored information. If some code has a chunk
lock and wants to acquire a terrain lock, but some other code already has a terrain lock and is
waiting for a chunk lock, you will get a deadlock. This can be a lot more subtle than a regular
deadlock. The rule of thumb here is to only get more and more specific locks when locking and avoid
having a specific lock while getting a general lock. If impossible (or tedious) to obey this rule in
a certain bit of code, it is also possible to use caution and carefully ensure that one of the
offending bits of code only takes one lock at a time (as seen in commit
[17fb74bc36ad5b6619d6a6066ebf47073ff22659](https://github.com/stackotter/delta-client/commit/17fb74bc36ad5b6619d6a6066ebf47073ff22659)).

## `ClientboundEntityPacket`'s

When implementing the `handle` method of a `ClientboundEntityPacket`, ensure that you do not attempt
to acquire any locks on the ECS nexus. This is because these packets are handled in the
`EntityPacketSystem` which is run during the game tick, and the tick scheduler always acquires a
write lock on the nexus before running any systems.

## Finding the offending code (in trickier cases)

If you are struggling to identify a deadlock cause, try defining the `DEBUG_LOCKS` flag. This
enabled the `lastLockedBy` property on `ReadWriteLock` which stores the file, line and column where
the lock was most recently acquired. Use the [`swiftSettings`](https://github.com/apple/swift-package-manager/blob/11ae0a7bbfaab580c5695eea2c76db9ab092b8a4/Documentation/PackageDescription.md#methods-9)
property of the Swift package target you are building to define the flag.

After defining the `DEBUG_LOCKS` flag, run the program under lldb or the Xcode debugger and wait for
the deadlock to occur. Find a thread that is stuck waiting for a lock and inspect the lock's
`lastLockedBy` property. This will hopefully help you find the code path that either forgot to unlock
the lock or is acquiring a lock twice.
