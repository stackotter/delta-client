# Demo Versions

The demo versions are just milestones that work towards the first Alpha release

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

## Demo 3 - Improved Rendering *(WIP)*

### New Features

- basic shading
- multipart structures
- random block rotations
- multichunk rendering
- other rendering fixes

### Todo

- [x] multipart structure reading (from pixlyzer)
- [x] multipart structure rendering
- [ ] random variants
- [ ] proper random block rotations (that match vanilla)
- [ ] basic shading
- [ ] rework & optimise chunk mesh preparation
- [ ] basic multichunk rendering
- [ ] fix hypixel chunk loading
- [ ] fix grass block sides
- [ ] implement rescale
- [ ] possibly use section based rendering instead of chunk based
- [ ] parallelise generating chunk meshes
- [ ] order chunks based on distance from player when generating meshes

## Demo 4 - Movement

### New Features

- basic controls
  - position
  - look
- basic physics loop (without gravity)

### Todo

- [ ] create an input system
  - [ ] keyboard
  - [ ] mouse
- [ ] create a physics loop
  - [ ] make a loop that runs at a consistent interval
  - [ ] add basic physics simulation
- [ ] hook up input system to send packets to server
- [ ] add input settings (mouse sensitivity and keymappings)

## Demo 5 - Code & UI Improvements

### New Features

- cleaner code
- improved ui
- improved error handling and displaying
- improved startup verbosity

### Todo

- [ ] rework ui code
- [ ] rewrite ui code like the fruta example
- [ ] rework mojang api and login flow
- [ ] find and remove redundant code
- [ ] maybe remove commands mode
- [ ] improve error handling and displaying
- [ ] use count up down latch thingo like minosoft for startup sequence

## Demo 6 - Multi-accounting

### Features

- offline account support
- microsoft accounts
- multi-accounting

### Todo

- [ ] add basis for multi-accounting
  - [ ] config
  - [ ] login code
- [ ] add offline account support
- [ ] add microsoft account support
- [ ] ui for switching accounts

## Demo 7 - Collisions and Proper Physics

### New Features

- collision system
- auto-jump
- gravity (for noobs)

### Todo

- [ ] load hitboxes
- [ ] wireframe hitboxes
- [ ] detect player-block collisions
- [ ] handle collisions
- [ ] auto-jump
- [ ] add gravity to physics

# Alpha Versions

The alpha versions will still be far from useable but a majority of the groundwork will be there.

These versions will also start looking a lot more like the real thing.

## Alpha 1 - Basic Survival Mode

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