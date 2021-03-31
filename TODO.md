# Version 1.0.0 Alpha TODOs

- [ ] Refactor networking and add compression and encryption support
- [ ] remove need for minecraft to be already installed

# General TODOs

## Networking

- [ ] Refactor networking into a network stack
  - [ ] Initial refactor
  - [ ] Compression layer
  - [ ] Encryption layer

## Config

- [ ] Read server list and stuff from actual file instead of mojang ones (no dependence on minecraft being installed then)
- [ ] Basic config system

## Startup

- [ ] fix message for block palette manager being incorrect when generating palette and not first launch

## Rendering

- [ ] basic shading
- [ ] multiple chunks first test
- [ ] look into keeping vertices in gpu mem when they are unchanged between frames?
- [ ] split translucent blocks into separate file
- [ ] animated textures
- [ ] multipart structures

## Block models

- [ ] multipart
- [ ] multiple models for one block
- [ ] fix stair sides not being detected as full faces (because they're made of two elements)
- [ ] separate out block model structs into separate files
- [ ] investigate campfires
- [ ] identify translucent blocks

## Chunk preparing

- [ ] fix glass block xray. detect when full faces are not culling full faces (when they are transparent)
- [ ] optimise new parts
- [ ] optimise by replacing the slowest parts with c probably lol
- [ ] fix grass block overlay render order (possibly just bodge and make the underneath element slightly smaller)

## General clean up

- [ ] improve error handling in networking
- [ ] use swifts fancy json instead of mine

## Other

- [ ] add os_signpost support to the stopwatch
- [ ] rename project to not include word minecraft
- [ ] remove reliance on minecraft folder
