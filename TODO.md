## UI

- [ ] fix refresh button looking like it's disabled after clicking

## Networking

- [x] Refactor networking into a network stack
  - [x] Initial refactor
  - [x] Compression layer
  - [ ] Encryption layer
- [ ] mojang api
- [ ] create protocol definition file

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
- [ ] clean up json
- [x] rename project to not include word minecraft
- [ ] fix folder structure a little (not just delta-client/DeltaClient/DeltaClient to get to any code)
