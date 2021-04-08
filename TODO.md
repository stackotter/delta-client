## UI

- [ ] fix refresh button looking like it's disabled after clicking
- [ ] add more useful messages instead of just 'downloading terrain' when joining games
- [ ] rework to use event manager instead of passing around a reference to the view state
- [ ] rename serverlistview to homeview or something and appview to rootview or something

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

## Config

- [x] Basic config system
- [x] Remove dependence on vanilla minecraft installation being present
- [ ] prettify config json

## Startup

- [ ] fix message for block palette manager being incorrect when generating palette and not first launch

## Rendering

- [ ] basic shading
- [ ] multiple chunks first test
- [ ] look into keeping vertices in gpu mem when they are unchanged between frames?
- [ ] animated textures
- [ ] multipart structures

## Block models

- [ ] multipart
- [ ] multiple models for one block
- [ ] fix stair sides not being detected as full faces (because they're made of two elements)
- [x] separate out block model structs into separate files
- [ ] investigate campfires
- [ ] investigate levers (point the opposite way compared to vanilla. probably an order of rotations thing?)
- [ ] investigate falsely culled path block top face (under haybale)
- [ ] investigate cauldron water not showing
- [ ] identify translucent blocks
- [ ] detect when full faces are not culling full faces (when they are transparent)
- [ ] fix path block xray

## Chunk preparing

- [ ] optimise new parts
  - [ ] optimise by replacing the slowest parts with c probably lol
- [ ] fix grass block overlay render order (possibly just bodge and make the underneath element slightly smaller)
- [ ] split translucent blocks into separate file
- [ ] split transparent and translucent blocks into separate meshes

## General

- [x] improve error handling in networking
- [ ] use swifts fancy json instead of mine
- [ ] clean up json reader/writer
- [x] rename project to not include word minecraft
- [ ] fix folder structure a little (not just delta-client/DeltaClient/DeltaClient to get to any code)
- [ ] fix leave server's ram issue
