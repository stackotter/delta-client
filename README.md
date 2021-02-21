# Minecraft Swift Edition

## Overview

Minecraft Swift Edition is an open source rewrite of Minecraft Java Edition written in Swift. It is only a rewrite of the part that allows playing on servers.

Currently it uses no external libraries so the app is currently less than a mb.

## Roadmap

- [x] Server list ping (reads server list from servers.dat)
- [x] Create nice UI using SwiftUI
- [ ] Login 
  - [x] Without encryption and compression
  - [ ] With compression
  - [ ] With encryption
- [ ] Be able to decode all clientbound packets
  - [ ] status
  - [ ] login
  - [x] play
- [ ] Be able to send all serverbound packets
  - [ ] status
  - [ ] login
  - [x] play
- [ ] Handle all packets
  - [ ] status
  - [ ] login
  - [ ] play
    - [ ] entities
    - [ ] everything else
- [ ] Complete networking (so that i don't need to touch it again)
- [ ] Create basic text interface
  - [ ] chat
  - [ ] movement
  - [ ] tablist
  - [ ] view entities
  - [ ] minimap just for fun?
  - [ ] maybe some block actions too?
- [ ] Entities (entity mappings and stuff)
- [ ] Basic rendering using Metal (Apple's GPU library)
  - [ ] Block rendering
  - [ ] Block Animations
  - [ ] Block entity rendering
  - [ ] Entity rendering
  - [ ] Chat Rendering
  - [ ] GUI Rendering (inventory and hot bar and the likes)
- [ ] Physics
- [ ] Inventory
  - [ ] Crafting
  - [ ] Other crafting (like smelting and stuff)

## Screenshots

### Server List

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/hypixel.png?raw=true)
