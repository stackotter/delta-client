## Priorities

1. [x] multi-accounting
   1. [x] ditch microsoft accounts for now (until someone complains)
   2. [x] create account switcher
2. [x] thread safety in chunk loading, preparing and rendering
3. [x] complete rendering restructure
4. [x] consistent chunk loading on higher render distance default generation worlds
5. [ ] use lighting data sent from server

## UI

- [x] fix ui consistency
- [x] use environment object to pass view state around
- [ ] fix dismissing error screens

## Networking

- [x] Refactor networking into a network stack
  - [x] Initial refactor
  - [x] Compression layer
  - [x] Encryption layer
- [x] mojang api
  - [x] refresh access token
- [ ] create protocol definition file
- [ ] fix error handling for mojang api (probably with event manager) (at the moment the errors are silent)
- [ ] shutdown networking properly when leaving server
  - [ ] teardown server and client objects properly
- [ ] get new chunks receiving when player is moved
- [ ] auto-respawn

## Config

- [x] Basic config system
- [x] Remove dependence on vanilla minecraft installation being present
- [x] prettify config json

## Startup

- [ ] fix message for block palette manager being incorrect when generating palette and not first launch

## Rendering

- [x] basic shading
- [ ] fix chunks not loading (lighting data issue?)
- [x] multiple chunks first test
- [x] look into keeping vertices in gpu mem when they are unchanged between frames?
- [ ] look into using private storage instead of shared for vertex buffers
- [ ] animated textures
- [ ] multipart structures
- [ ] fix block changes having incorrect culling
- [ ] fix indices (either use 6 vertices to a face or do the fancy shader thing from before so that all the index buffers aren't needed anymore)
- [x] investigate why the initial chunks at 10 render distance take so long to load
- [x] wait for neighbouring chunks
- [ ] make bottom face of block the darkest
- [x] fix precision errors (an issue with near and far being too different, raising near to 0.1 could probably help)
- [x] completely refactor
- [x] fix face culling between chunks (could possibly make get neighbourBlockStates function to make a less complex solution than last time)

## Block models

- [x] multipart
- [ ] fix stair sides not being detected as full faces (because they're made of two elements)
- [x] separate out block model structs into separate files
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
- [ ] fix most of the above issues and then rewrite block model loading

## Chunk preparing

- [ ] optimise new parts
  - [ ] optimise by replacing the slowest parts with c probably lol
- [ ] fix grass block overlay render order (possibly just bodge and make the underneath element slightly smaller)
- [ ] split translucent blocks into a separate palette? or at least have a nice way of knowing if a block counts as translucent, transparent or opaque
- [ ] split translucent blocks into a separate mesh type?
- [ ] make a generic cubemesh object? that has adding elements and stuff so that it can be reused for entities later?
- [x] fix chunk preparing order in new rendering system (it doesn't reevaluate the order of chunks to prepare when the player turns around, could possibly fix this by only allowing 3 frozen chunks at a time and re-evaluating chunk order after every 3?)
- [ ] fix random faces of blocks randomly not deleting (possibly rewrite meshing system)
- [x] fix multiblock changes
- [ ] fix chunk updates caused by things like tnt that just resend part of the affected chunk instead of using a multi-block change

## General

- [ ] add version to block model cache and config to know when to remake them (as api is not stable yet)
- [ ] rename protobuf cache message thingos to be Cached instead of Cache
- [x] improve error handling in networking
- [ ] clean up json reader/writer
  - [ ] use swifts fancy json instead of mine
- [x] rename project to not include word minecraft
- [x] fix folder structure a little (not just delta-client/DeltaClient/DeltaClient to get to any code)
- [ ] fix leave server's ram issue
- [ ] separate protocol into protocol and network
- [x] make mesh a protocol and extension, not a class
- [x] re-enable sandbox
- [ ] clean up matrixutil to be a matrix_float4x4 extension possibly?
- [ ] use rethrows
- [x] simplify data classes (like chunk) that should just be a data source
- [x] have a default eventmanager (treat it as a singleton)
- [ ] make most of the managers singletons where possible (hopefully get rid of Managers)
  - [ ] https://forums.swift.org/t/is-there-any-way-to-throw-error-from-singleton-class-init/39207, https://medium.com/@tlimaye91/thread-safe-singletons-in-swift-a4f6a977d6e6
- [ ] potentially move over to using Carthage instead of swift package manager
- [x] use new position properties instead of all the spread out functions now
- [ ] move all issues from here to issue tracker

## Architecture

- [x] World should eventually be mostly structs and just contain helper methods and be used a data holder (chunks shouldn't need to update their meshes and stuff probably, that's chunk preparers job, could involve callbacks though)
- [x] the rest of the code shouldn't know that rendering even exists (the renderer should just observe the world)
- [ ] nbt code as encoder and decoder maybe?
- [ ] merge client and server into client (i am not making a server, there should be just a Client and a ServerConnection)
- [ ] make ConfigManager singleton?
- [ ] PhysicEngine should be able to take World as input instead of Client

## Optimisation

- [ ] fix ram usage and find why ram usage is so high after first launch

## Code Cleanup

- [x] restructure folder structure
- [ ] split buffer into InBuffer and OutBuffer
- [x] always use the position type instead of separate x, y and z arguments
- [x] get rid of getIndexForBlock or whatever and use the calculated property of Position
- [ ] fix SwiftLint stuff
- [ ] meet the airbnb swift style guidelines
  - [ ] use MARK
- [ ] fix error handling
- [ ] create logging guidelines and conform to them (like about what log levels to use when)
- [ ] create error guidelines and conform to them (like about when to throw errors and when to return nil and where to put error enums)
- [ ] use american spellings
- [ ] make wrapper view for adding titles
- [ ] create swiftui previews for all views
- [ ] make proper alert system (for popup errors)
- [ ] use enums and extensions of those enums to do namespacing (instead of a flat namespace)
- [x] refactor rendering completely to be more oop style and cleaner (hopefully optimising it a bit along the way too)