# TODOS

## Networking

- [ ] Support compression
- [ ] Support encryption

## Config

- [ ] Read server list and stuff from actual file instead of mojang ones (no dependence on minecraft being installed then)
- [ ] Basic config system

## Startup

- [ ] cache global palette
- [ ] make managers throw in initialiser to avoid optional and throwing functions elsewhere
  - [ ] storage manager
  - [ ] asset manager
  - [ ] texture manager
  - [ ] block model manager (rename this too)

## Rendering

- [ ] transparency
- [ ] look into keeping vertices in gpu mem when they are unchanged between frames?

### Chunk preparing

- [ ] speed up chunk preparing
  - [ ] flatten the for loops used
  - [ ] for checking neighbours use math on the indices instead of looking up block at x, y, z etc.
- [ ] reimplement block changes
- [ ] improve block culling under new block model rendering
  - [ ] figure out how cull faces work

## General clean up

- [ ] improve error handling in networking (certain things like readIdentifier probably don't need to throw)