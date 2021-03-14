# Minecraft Swift Edition

## Overview

Minecraft Swift Edition is an open source rewrite of Minecraft Java Edition written in Swift. It is only a rewrite of the part that allows playing on servers.

## Roadmap

- [ ] Networking
  - [x] Basic networking
  - [ ] Packet Decoding
    - [x] Handshaking
    - [ ] Status
      - [x] Server list ping
      - [ ] Ping/pong
      - [ ] Legacy server ping
    - [ ] Login
      - [x] The essential packets
      - [ ] Encryption packets
      - [ ] Compression packets
    - [x] Play
  - [ ] Packet Handling
    - [ ] Login
      - [x] Basic login flow
      - [ ] Mojang account login
      - [ ] Microsoft account login
  - [ ] Protocol Layers
    - [ ] Compression
    - [ ] Encryption
  - [ ] Lan worlds
- [ ] First Launch
  - [x] Download assets
  - [ ] Generate default config
  - [ ] Progress bar for client jar download (downloading assets)
  - [ ] One-time setup screen?
- [ ] Mojang Data
  - [ ] Block data
    - [x] Load global block palette
    - [x] Load block states
    - [x] Load block models
    - [x] Load block textures
    - [ ] Flatten block models to better format
  - [ ] Item data
  - [ ] Entity data
  - [ ] Sound data
- [ ] Config
  - [ ] Create a config system
  - [ ] Make an interface for it
- [ ] Command-based interface
  - [x] Basic structure
  - [x] Chat command
  - [x] Tab list command
  - [ ] Action commands
  - [ ] Movement commands
- [ ] Rendering
  - [ ] Chunks
    - [x] Basic block rendering
    - [x] Basic chunk rendering
    - [x] Block culling
    - [ ] Block models
    - [ ] Random block models (randomly picked based on location it's placed at)
    - [ ] Multiple chunks
    - [ ] Animated textures
    - [ ] Block entities
    - [ ] Chunk culling
  - [ ] HUD
    - [ ] Basic text
    - [ ] Chat
    - [ ] F3-style stuff
    - [ ] Bossbars
  - [ ] Items
  - [ ] Entities
    - [ ] Basic entity rendering (maybe just a coloured cube)
    - [ ] Render entity models
    - [ ] Entity animations
- [ ] GUI
  - [ ] Health
  - [ ] Hunger
  - [ ] Experience
  - [ ] Hotbar
  - [ ] Inventory
    - [ ] Basic inventory
    - [ ] Basic inventory actions
    - [ ] Basic crafting
    - [ ] Drag actions
    - [ ] Using recipe blocks (like crafting tables and stuff)
- [ ] Sound
  - [ ] Basic sounds
  - [ ] Sound settings??
- [ ] Particles
  - [ ] Basic particles
  - [ ] Block break particles
  - [ ] Walk on block particles
  - [ ] Ambient particles
  - [ ] Hit particles
  - [ ] Other particles

## Command Interface

At the moment when the client is connected to a server it gives you a text field for entering commands.

These are not commands in the traditional minecraft sense (e.g. ```/kill``` and ```/time set day```). They are commands that I have made that let you interact with the server.

As I implement more of the backend code -- and before I work on rendering -- I will be making more commands to reflect the current capabilities of the client. In future I will most likely also make a command for running commands on the server (this is starting to get confusing).

#### Current Commands

- ```say [message]```
  - sends a message in chat
- ```swing [mainhand|offhand]```
  - causes the player's arm to swing. can be used to say hi to other players :) (and also just to test if it's working)
- ```getblock [x] [y] [z]```
  - gets the block state id of the block at position

## Screenshots

#### Server List

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/hypixel.png?raw=true)

#### Playing Server Screen

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/play-screen.png?raw=true)
