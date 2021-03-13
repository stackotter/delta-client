# TODOS

just a bunch of random todos

- [x] Clean up serverbound networking
- [ ] Support compression
- [x] Implement all serverbound play packets
- [ ] Move enums and structs from packets to sensible places
- [x] Process chunk data in another thread
  - [ ] Check if i actually did this i can't remember
- [x] Optimise chunk data processing
  - [ ] Optimise it more
- [ ] Chunk rendering
  - [x] Textureless blocks
  - [x] Make it 60fps
  - [x] Optimise initial mesh preparation
  - [x] Implement block culling (saves on cpu and memory usage) (basic block culling)
  - [ ] Implement basic block textures
  - [ ] Fix block culling to be able to do blocks on the edge of chunks
  - [ ] Optimise block culling more
- [ ] Mojang data
  - [x] create startup sequence
  - [x] plan directory structure
  - [ ] download the mojang data on first app launch to avoid copyright stuff
    - [x] can probably just extract from the client.jar pretty easily
  - [ ] load block models and block state info stuff from texture pack
  - [ ] fix config loader
  - [x] fix locale usage throughout project
  - [ ] delete mojang files from resources folder to avoid copyright stuff
- [ ] clean up server list loading (server list manager?)