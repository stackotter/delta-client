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
  - [ ] Optimise initial mesh preparation
  - [ ] Implement block culling (saves on cpu and memory usage)
  - [ ] Implement basic block textures
- [ ] Mojang data
  - [ ] download the mojang data on first app launch to avoid copyright stuff
    - [ ] can probably just extract from the server.jar pretty easily
  - [ ] load block models and block state info stuff from texture pack
  - [ ] fix config loader