# TODOS

## Networking

- [ ] Support compression
- [ ] Support encryption

## Config

- [ ] Read server list and stuff from actual file instead of mojang ones (no dependence on minecraft being installed then)
- [ ] Basic config system

## Startup

- [ ] optimise creation of global palette
- [ ] cache global palette
- [ ] make managers throw in initialiser to avoid optional and throwing functions elsewhere
  - [ ] storage manager
  - [ ] asset manager
  - [ ] texture manager
  - [ ] block model manager (rename this too)

## Rendering

- [x] transparency
- [x] fix near clipping plane
- [x] sky colour
- [ ] translucency
- [ ] look into keeping vertices in gpu mem when they are unchanged between frames?
- [ ] animated textures
- [ ] multipart structures
- [x] render looking the correct direction (use player look from position and look)
- [x] uvlock
- [x] get terracotta rotations working

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

## General clean up

- [ ] improve error handling in networking
- [x] use normal int and uint types instead of specifying 32 or 64. avoids annoying conversions

## Other

- [ ] add os_signpost support to the stopwatch
- [ ] rename project to not include word minecraft
