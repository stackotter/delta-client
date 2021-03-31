# TODOS

## Networking

- [ ] Refactor networking into a network stack
  - [ ] Initial refactor
  - [ ] Compression layer
  - [ ] Encryption layer
- [x] Optimise chunk data decoding

## Config

- [ ] Read server list and stuff from actual file instead of mojang ones (no dependence on minecraft being installed then)
- [ ] Basic config system

## Startup

- [x] optimise creation of global palette
- [x] cache global palette
- [x] make managers throw in initialiser to avoid optional and throwing functions elsewhere
  - [x] storage manager
  - [x] asset manager
  - [x] texture manager
  - [x] block model manager
- [ ] rename block model manager

## Rendering

- [x] transparency
- [x] fix near clipping plane
- [x] sky colour
- [ ] basic shading
- [ ] translucency
- [ ] look into keeping vertices in gpu mem when they are unchanged between frames?
- [ ] animated textures
- [ ] multipart structures
- [x] render looking the correct direction (use player look from position and look)
- [x] uvlock
- [x] get terracotta rotations working
- [x] fix upside-down stairs (the uvlock doesn't work for the side textures)

### Block models

- [ ] multipart
- [ ] multiple models for one block
- [x] implied uv coordinates
- [ ] fix stair sides not being detected as full faces (because they're made of two elements)
- [ ] fix uvlock again
- [x] fix cauldrons again

### Chunk preparing

- [x] speed up chunk preparing
  - [x] flatten the for loops used
  - [x] for checking neighbours use math on the indices instead of looking up block at x, y, z etc.
- [x] reimplement block changes
- [x] improve block culling under new block model rendering
- [x] implement looking in neighbouring chunks for edge block cull faces
- [x] make chunk mesh thread safe
- [x] fix plants (based on the cross block model) (probably something to do with rotation and rescale)
- [x] fix stairs
- [x] block rotations
- [x] fix x-ray from partial blocks
  - [x] generate list of full faces for each block from block models
- [ ] optimise new parts
- [ ] optimise by replacing the slowest parts with c probably lol
- [ ] fix grass block overlay render order (possibly just bodge and make the underneath element slightly smaller)

## Other chunk stuff

- [x] multi block changes
- [ ] multiple chunks first test

## General clean up

- [ ] improve error handling in networking
- [x] use normal int and uint types instead of specifying 32 or 64. avoids annoying conversions
- [ ] use swifts fancy json instead of mine

## Other

- [ ] add os_signpost support to the stopwatch
- [ ] rename project to not include word minecraft
