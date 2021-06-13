# Todo

I kind of just put current todos here and also things that I'm putting off until later. But if you just want to know how development is going the roadmap in the README will give you a better overall idea of how complete the project is. And `ROADMAP.md` contains more details on planned releases and stuff. This file is really just for me to keep a whole mess of todos and reminders in.

## Priorities

1. [ ] reduce cpu time for rendering (gpu time is around 8ms whereas cpu time is around 16ms)
2. [ ] optimise chunk mesh preparation
3. [ ] fix memory loops (client or server or something like that is retained after leaving server)
4. [ ] clean up WorldRenderer
5. [ ] fix frustum culling lagging behind actual view
6. [ ] rewrite block model loading
7. [ ] properly render transparency
8. [ ] properly render translucency
9. [ ] implement proper lighting

## UI

- [ ] fix dismissing error screens
- [ ] make wrapper view for adding titles
- [ ] create swiftui previews for all views
- [ ] make proper alert system (for popup errors)?
- [ ] fix bug that lets you initial launch the client and then doesn't get you to add an account

## Networking

- [ ] create protocol definition file
- [ ] fix error handling for mojang api (probably with event manager) (at the moment the errors are silent)
- [ ] shutdown networking properly when leaving server
  - [ ] teardown server and client objects properly (or just avoid creating reference cycles)
- [ ] get new chunks receiving when player is moved
- [ ] auto-respawn

## Config

- [ ] keymapping
- [ ] mouse sensitivity

## Cache

- [ ] add version to block model cache to know when to regenerate it (as api is not stable yet)

## Startup

- [ ] make startup messages more descriptive
- [ ] use async/await patterns to further speed up startup (if possible)
- [ ] possibly a progress bar for downloading client jar on first launch?

## Rendering

- [ ] look into using private storage instead of shared for vertex buffers
- [ ] animated textures
- [ ] lighting
- [ ] possibly remove need for indices buffers (either use 6 vertices to a face or do the fancy shader thing from before so that all the index buffers aren't needed anymore)
- [ ] use face normals for consistent block shading
- [ ] use new async/await for concurrency in rendering
- [ ] split opaque and translucent textures into separate texture arrays to fix mip map issues

## Block models

- [ ] fix stair sides not being detected as full faces (because they're made of two elements)
- [ ] investigate campfires (probably animated textures?)
- [ ] investigate levers (point the opposite way compared to vanilla. probably an order of rotations thing?)
- [ ] investigate falsely culled path block top face (under haybale)
- [ ] investigate cauldron water not showing
- [ ] identify translucent blocks
- [ ] detect when full faces are not culling full faces (when they are transparent)
- [ ] cull faces between path blocks
- [ ] stop using a dictionary for the block palette, just use an array
- [ ] respect weighting for block variants
- [ ] fix stairs again (an upside-down stair with a block against each full face has a bunch of incorrect culling)
- [ ] piston textures
- [ ] fences with block on top don't render? (fence posts at least)
- [ ] top half of door doesn't render from inside of house
- [ ] rewrite block model loading and fix all the above issues while i'm at it hopefully
- [ ] potentially use the swift-numerics library for approximate equality and stuff

## Chunk preparing

- [ ] split translucent blocks into a separate palette? or at least have a nice way of knowing if a block counts as translucent, transparent or opaque
- [ ] split translucent blocks into a separate mesh type (for all the resorting stuff)?

## Memory

- [ ] find and remove reference cycles (i think there are a lot)
- [ ] use weak self pattern in escaping closures where other solutions (like async/await) are not viable

## General

- [ ] rename protobuf cache message thingos to be Cached instead of Cache
- [ ] clean up json reader/writer
  - [ ] use swifts fancy json instead of mine
- [ ] separate protocol into protocol and network
- [ ] clean up matrixutil to be a matrix_float4x4 extension possibly?
- [ ] use rethrows where applicable
- [ ] potentially move over to using Carthage instead of swift package manager
- [ ] add Comparable conformance to LogLevel to allow for easily setting a level to display the 'At' component for (`logLevel >= .warning` for example) 

## Architecture and Code Cleanup

- [ ] nbt code as encoder and decoder maybe?
- [ ] merge client and server into client (i am not making a server, there should be just a Client and a ServerConnection)
- [ ] make ConfigManager singleton?
- [ ] PhysicEngine should be able to take World as input instead of Client
- [ ] split buffer into InBuffer and OutBuffer
- [ ] fix SwiftLint stuff
- [ ] meet the airbnb swift style guidelines
  - [ ] use MARK
- [ ] fix error handling
- [ ] create logging guidelines and conform to them (like about what log levels to use when)
- [ ] create error guidelines and conform to them (like about when to throw errors and when to return nil and where to put error enums)
- [ ] use american spellings
- [ ] use enums and extensions of those enums to do namespacing (instead of a flat namespace)
- [ ] make most of the managers singletons where possible (hopefully get rid of Managers)
  - [ ] https://forums.swift.org/t/is-there-any-way-to-throw-error-from-singleton-class-init/39207, https://medium.com/@tlimaye91/thread-safe-singletons-in-swift-a4f6a977d6e6
