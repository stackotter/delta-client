# Roadmap

## Demo 1 - Basic Demo (Completed)

### Features

- smooth first launch flow (downloading assets and creating default config and stuff)
- login flow for mojang accounts
- fast subsequent startups
- rendering player's current chunk
  - can be moved around using ```tp``` commands from another player
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

## Demo 2 - Bug fixes for basic features

### Todo

- [x] refresh access token before each server join
- [ ] fix first time server join

## Demo 3 - Better Rendering (Current target)

### Features

- basic input system (basically spectator mode)
  - won't be hypixel-safe lol
- basic shading
- multichunk rendering
- multipart structures

### Todo

- [ ] basic shading
- [ ] multipart structure parsing
- [ ] multipart structure rendering
- [ ] refactor chunk mesh preparation
- [ ] optimise chunk mesh preparation (using c most likely)
- [ ] basic multichunk rendering
- [ ] create basic input system
- [ ] create basic physics system (for movement, no gravity)

## Demo 4 - Cleaner UI + General Code Cleanup

### Features

- cleaner code
- improved ui
- improved error handling and displaying
- offline account support
- microsoft accounts
- multi-accounting

### Todo

- [ ] rework ui code
- [ ] rework mojang api and login flow
- [ ] find and remove redundant code
- [ ] maybe remove commands mode
- [ ] improve error handling and displaying
- [ ] add offline account support
- [ ] add multi accounting
- [ ] add microsoft account support
- [ ] use count up down latch thingo like minosoft for startup sequence

## Demo 5 - iOS/iPadOS

### Features

- working iOS builds
- working iPadOS builds

### Todo

- [ ] add iOS build target
- [ ] add iPadOS build target
- [ ] provide iOS specific code for NSViewRepresentable and stuff
- [ ] fix any iOS specific bugs
- [ ] tweak ui for iPad