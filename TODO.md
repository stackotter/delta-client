## UI

- [ ] fix refresh button looking like it's disabled after clicking
- [ ] add more useful messages instead of just 'downloading terrain' when joining games
- [ ] rework to use event manager instead of passing around a reference to the view state
- [ ] rename serverlistview to homeview or something and appview to rootview or something
- [ ] auto-dismiss error when logout is clicked

## Networking

- [x] Refactor networking into a network stack
  - [x] Initial refactor
  - [x] Compression layer
  - [x] Encryption layer
- [x] mojang api
  - [x] refresh access token
- [ ] create protocol definition file
- [ ] fix initial ping being weird (a packet is being sent when it shouldn't be)
- [ ] investigate empty packets
- [ ] fix error handling for mojang api (probably with event manager) (at the moment the errors are silent)
- [ ] shutdown networking properly when leaving server
  - [ ] teardown server and client objects properly
- [ ] get new chunks receiving when player is moved
- [ ] auto-respawn

## Config

- [x] Basic config system
- [x] Remove dependence on vanilla minecraft installation being present
- [ ] prettify config json

## Startup

- [ ] fix message for block palette manager being incorrect when generating palette and not first launch

## Rendering

- [ ] basic shading
- [x] multiple chunks first test
- [x] look into keeping vertices in gpu mem when they are unchanged between frames?
- [ ] look into using private storage instead of shared for vertex buffers
- [ ] animated textures
- [ ] multipart structures
- [ ] fix block changes having incorrect culling
- [ ] fix indices (either use 6 vertices to a face or do the fancy shader thing from before so that all the index buffers aren't needed anymore)
- [ ] investigate why the initial chunks at 10 rener distance take so long to load
- [ ] wait for neighbouring chunks
- [ ] make bottom face of block the darkest
- [ ] fix precision errors (an issue with near and far being too different, raising near to 0.1 could probably help)

## Block models

- [x] multipart
- [ ] multiple models for one block
- [ ] fix stair sides not being detected as full faces (because they're made of two elements)
- [x] separate out block model structs into separate files
- [ ] investigate campfires (probably animated textures?)
- [ ] investigate levers (point the opposite way compared to vanilla. probably an order of rotations thing?)
- [ ] investigate falsely culled path block top face (under haybale)
- [ ] investigate cauldron water not showing
- [ ] identify translucent blocks
- [ ] detect when full faces are not culling full faces (when they are transparent)
- [ ] fix path block xray
- [ ] stop using a dictionary for the block palette, just use an array
- [ ] respect weighting for block variants
- [ ] fix stairs again (an upside-down stair with a block against each full face has a bunch of incorrect culling)
- [ ] piston textures
- [ ] levers going the wrong way

## Chunk preparing

- [ ] optimise new parts
  - [ ] optimise by replacing the slowest parts with c probably lol
- [ ] fix grass block overlay render order (possibly just bodge and make the underneath element slightly smaller)
- [ ] split translucent blocks into separate file
- [ ] split transparent and translucent blocks into separate meshes

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
- [ ] simplify data classes (like chunk) that should just be a data source
- [ ] use some concurrent dispatchqueues
- [x] have a default eventmanager (treat it as a singleton)
- [ ] make most of the managers singletons where possible (hopefully get rid of Managers)
  - [ ] https://forums.swift.org/t/is-there-any-way-to-throw-error-from-singleton-class-init/39207, https://medium.com/@tlimaye91/thread-safe-singletons-in-swift-a4f6a977d6e6
- [ ] potentially move over to using Carthage instead of swift package manager
- [ ] use new new position properties instead of all the spread out functions now
- [ ] always use the position type as the argument to functions
- [ ] initialise world to an EmptyWorld instead of optional

## Architecture

- [ ] World should eventually be mostly structs and just contain helper methods and be used a data holder (chunks shouldn't need to update their meshes and stuff probably, that's chunk preparers job, could involve callbacks though)
- [ ] the rest of the code shouldn't know that rendering even exists (the renderer should just observe the world)

## Optimisation

- [ ] fix ram usage and find why ram usage is so high after first launch

## Code Cleanup

- [ ] restructure folder structure
- [ ] split buffer into InBuffer and OutBuffer
- [ ] always use the position type instead of separate x, y and z arguments
- [ ] get rid of getIndexForBlock or whatever and use the calculated property of Position
- [ ] fix SwiftLint stuff
- [ ] meet the airbnb swift style guidelines
  - [ ] use MARK