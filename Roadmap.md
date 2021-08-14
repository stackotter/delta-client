# **This is outdated, please ignore for now**

# Demo Versions

The demo versions are just proof-of-concepts.

## Demo 1 - Efficient Launch, Basic Rendering & All Networking *(Released)*

### Features

- smooth first launch flow (downloading assets and creating default config and stuff)
- login flow for mojang accounts
- fast subsequent startups
- rendering player's current chunk
  - the view can be moved around using ```tp``` commands from another player
- basic config screens (account settings and server settings)

### Todo

- [x] refactor networking
- [x] add compression support
- [x] add encryption support
- [x] basic config system
- [x] sign in screen on first launch
- [x] config screen for changing account details (used a logout button for now instead)
- [x] remove need for minecraft to be already installed
- [x] add basic way to exit game and get back to server list
- [x] prettyprint config json
- [x] way to re-order servers
- [x] move some things to menu bar instead of tool bar (like account stuff)

## Demo 2 - Critical Bug Fixes for Demo 1 *(Released)*

### New Features

- none, just fixes some critical bugs from demo 1

### Todo

- [x] refresh access token before each server join
- [x] fix first time server join

# Alpha Versions

The demo versions were just proof-of-concepts. The alpha versions will still be far from complete but will be looking a lot more promising.

## Alpha 1 - Basically Spectator Mode *(WIP)*

### New Features

- rendering
  - proper lighting
  - multipart structures (e.g. fences)
  - random block rotations
  - multichunk rendering
  - complete redesigned rendering system
  - animated textures
  - frustum culling
  - mip maps
  - proper tints (redstone, leaves, water and grass etc.)
  - fluids
  - proper transparency and translucency rendering
- movements
  - basic input system
  - basic spectator mode movement (freecam)
- ui
  - cleaner ui and ui code
  - edit server list screen
  - accounts screen
- multi-accounting (allow easily switching between accounts)
- improved memory usage

### Todo

- [x] multipart structure reading (from pixlyzer)
- [x] multipart structure rendering
- [x] parallelise generating chunk meshes
- [x] order chunks based on distance from player when generating meshes
- [x] order chunks based off frustum as well
- [x] basic shading (face normal based) (bake light levels into block models)
- [x] mip maps
- [x] rewrite block model loading system
- [x] lighting
- [x] animated textures
- [ ] fix gpu ram usage (clear buffers when not being used, possibly use private mode buffers, possibly use a big default size buffer and transfer things through that)
- [ ] fix indices (either use 6 vertices to a face or do the fancy shader thing from before (adjusting the vertex indices))
- [ ] optimise chunk mesh preparation
- [ ] proper transparent and translucent rendering
- [ ] non-transparent leaves for now (better performance)
- [ ] reduce cpu time for frames (gpu frame time is well below 16ms, cpu is taking up the majority of the time each frame)
- [x] possibly use section based rendering instead of chunk based
- [x] basic multichunk rendering
- [x] fix hypixel chunk loading
- [x] fix grass block sides
- [ ] implement rescale
- [ ] random block variants (that match vanilla)
- [x] frustum culling for chunks
- [x] create an input system
  - [x] keyboard
  - [x] mouse
- [x] create a physics loop
  - [x] make a loop that runs at a consistent interval
  - [x] add basic physics simulation
- [ ] add input configuration (mouse sensitivity and keymappings)
- [x] add basis for multi-accounting
  - [x] config
  - [x] login code
- [x] add offline account support
- [x] ui for switching accounts
- [ ] fix memory usage errors (when leaving a server or starting the app for the first time a lot of memory doesn't get freed for some reason)

## Alpha 2 - Creative Mode Without Inventory

### New Features

- collision system
- auto-jump
- gravity

### Todo

- [ ] load hitboxes
- [ ] wireframe hitboxes
- [ ] detect player-block collisions
- [ ] handle collisions
- [ ] auto-jump
- [ ] add gravity to physics

## Alpha 3 - Basic Survival Mode

### New Features - Basic HUD & Inventory

- f3
- hotbar
- health
- xp bar
- bubbles (the indicator for drowning stuff)
- basic inventory view

### Todo

- [ ] font rendering
- [ ] modular hud system
- [ ] bars
  - [ ] health
  - [ ] hunger
  - [ ] xp
  - [ ] bubbles
- [ ] item rendering
- [ ] hotbar
- [ ] basic inventory (just for viewing)