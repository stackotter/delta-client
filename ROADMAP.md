# Roadmap

## Demo 1

### Features

- smooth first launch flow (downloading assets and creating default config and stuff)
- login flow for mojang accounts
- fast subsequent startups
- rendering player's current chunk
  - can be moved around using ```tp``` commands from another player
- possibly iOS support depending on how feasible that turns out being

### Todo

- [x] refactor networking
- [x] add compression support
- [ ] add encryption support
- [ ] basic config system
- [ ] sign in screen on first launch
- [ ] config screen for changing account details
- [ ] remove need for minecraft to be already installed
- [ ] investigate iOS support

## Demo 2

### Features

- basic input system (basically spectator mode)
  - won't be hypixel-safe lol
- basic shading
- multichunk rendering
- multipart structures

### Todo

- [ ] create basic input system
- [ ] create basic physics system (for movement, no gravity)
- [ ] multipart structure parsing
- [ ] multipart structure rendering
- [ ] refactor chunk mesh preparation
- [ ] optimise chunk mesh preparation (using c most likely)
- [ ] basic multichunk rendering