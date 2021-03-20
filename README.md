# Minecraft Swift Edition

## Overview

Minecraft Swift Edition is an open source rewrite of Minecraft Java Edition written in Swift. It is only a rewrite of the part that allows playing on servers.

## Roadmap

- [ ] Networking
  - [x] Basic networking
  - [x] Server list ping
  - [ ] Encryption (for non-offline mode servers)
    - [ ] Mojang accounts
    - [ ] Microsoft accounts
  - [ ] LAN servers
- [ ] First Launch
  - [x] Download assets
  - [ ] Generate default config
- [ ] Mojang Data
  - [x] Load block models and global block palette
  - [ ] Item data
  - [ ] Entity data
  - [ ] Sound data
- [ ] Basic config interface
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
    - [ ] Multiple chunks
    - [ ] Animated textures
    - [ ] Block entities
    - [ ] Chunk culling
  - [ ] HUD
    - [ ] Basic text
    - [ ] Chat
    - [ ] F3-style stuff
    - [ ] Bossbars
    - [ ] Scoreboard
    - [ ] Health
    - [ ] Hunger
    - [ ] Experience
    - [ ] HUD for each gamemode
  - [ ] Items
  - [ ] Entities
    - [ ] Basic entity rendering (maybe just a coloured cube)
    - [ ] Render entity models
    - [ ] Entity animations
- [ ] GUI
  - [ ] Hotbar
  - [ ] Inventory
    - [ ] Basic inventory
    - [ ] Basic inventory actions
    - [ ] Basic crafting
    - [ ] Drag actions
    - [ ] Using recipe blocks (like crafting tables and stuff)
    - [ ] Creative inventory
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

These are NOT commands in the traditional minecraft sense (e.g. ```/kill``` and ```/time set day```). They are commands that I have made that let you interact with the server.

As I implement more of the backend code -- and before I work on rendering -- I will be making more commands to reflect the current capabilities of the client. In future I will most likely also make a command for running commands on the server (this is starting to get confusing).

#### Current Commands

- ```say [message]```
  - sends a message in chat
- ```swing [mainhand|offhand]```
  - causes the player's arm to swing. can be used to say hi to other players :) (and also just to test if it's working)
- ```tablist```
  - lists players in tab list
- ```getblock [x] [y] [z]```
  - gets the block state id of the block at position

## Screenshots

#### Server list

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/hypixel.png?raw=true)

#### Playing server with commands

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/play-screen.png?raw=true)

#### Current rendering (uses block models but has a bunch of weird things atm as you can probably tell)

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/rendering/first-block-model-rendering.png?raw=true)

#### The same place but in vanilla Minecraft

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/rendering/first-block-model-vanilla.png?raw=true)