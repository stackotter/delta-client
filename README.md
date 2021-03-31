# Minecraft Delta Client - Changing the meaning of speed

## Overview

Delta Client is an open source rewrite of Minecraft Java Edition written in Swift (and a bit of C for performance).

Eventually the project may be ported to iOS and iPadOS and maybe AppleTV to allow playing on Java Edition on platforms normally limited to Bedrock Edition 

## Metrics

Here's a list of the client's current numbers when run on my 2020 dual-core Intel i5 MacBook Air with 8gb of ram;

- launch time: 0.85s avg
  - vanilla Minecraft takes around 40s to launch on my laptop on average (47x slower)
- ram usage on home screen: 40mb avg
  - about the same as Vanilla Minecraft currently
- time taken to join server and have rendering: 1s
  - vanilla Minecraft is pretty random on this so it's hard to compare
  - and Delta Client currently only renders one chunk so it's a pretty unfair comparison anyway

## Roadmap

- [ ] Networking
  - [x] Basic networking
  - [x] Server list ping
  - [ ] Encryption (for non-offline mode servers)
    - [ ] Mojang accounts
    - [ ] Microsoft accounts
  - [ ] LAN servers
- [ ] Basic config system
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
    - [x] Block models
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
    - [ ] Health, hunger and experience
  - [ ] Items
  - [ ] Entities
    - [ ] Basic entity rendering (just coloured cubes)
    - [ ] Render entity models
    - [ ] Entity animations
- [ ] GUI
  - [ ] Hotbar
  - [ ] Inventory
    - [ ] Basic inventory
    - [ ] Basic crafting
    - [ ] Inventory actions
    - [ ] Using recipe blocks (like crafting tables and stuff)
    - [ ] Creative inventory
- [ ] Sound
  - [ ] Basic sounds system
- [ ] Particles
  - [ ] Basic particle system
  - [ ] Block break particles
  - [ ] Ambient particles
  - [ ] Hit particles
  - [ ] Particles from server

## Command Interface

Currently the client gives you the option to join a world in commands mode.

These are NOT commands in the traditional minecraft sense (e.g. ```/kill``` and ```/time set day```). They are basic commands that let you interact with the server.

More commands will probably be added later.

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

#### Current rendering

Rendering multiple chunks is coming next.

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/rendering/progress-5.png?raw=true)

#### The same place but in vanilla Minecraft

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/rendering/progress-5-vanilla.png?raw=true)
