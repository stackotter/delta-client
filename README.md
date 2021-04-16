# Minecraft Delta Client - Changing the meaning of speed

## Overview

Delta Client is an open source rewrite of Minecraft Java Edition written in Swift (Apple's modern programming language). The main focus of this project is to create a highly efficient Java Edition compatible client for macOS.

In the future the project will also hopefully support iOS, iPadOS and maybe tvOS. This would allow playing on Java Edition servers, on platforms normally limited to Bedrock Edition.

**I am NOT responsible for anti-cheat bans, the client has not been thoroughly tested yet and is still deep in development.**

## Minecraft version support

- [ ] 1.8.9 (will come once 1.16.1 is pretty polished)
- [x] 1.16.1

Once both of these versions are implemented, my plan is to add support for the following versions whenever a new one comes out;

- the latest speedrunning version (currently 1.16.1 and may be for a while)
- the latest stable version

## Installation

1. Download the latest release from the releases page
2. Unzip the download and open the application inside
3. You will get a security alert, click ok
4. Open System Preferences and navigate to 'Security & Privacy', and then to the 'General' tab
5. There should be a thing saying '"DeltaClient" was blocked from use...', click 'Open Anyway'
6. You should get another pop-up, click 'Open'
7. Wait for it to download and process the requirec assets (this only has to happen once and should take around 40s with a mediocre internet speed)
8. You can move DeltaClient to your Applications folder for ease of use if you want

## Usage

To try out the client follow the installation instructions and then add any server's you want to connect to. The servers must be 1.16.1 as this is the only version supported right now.

## Troubleshooting

As DeltaClient is still in development it is expected that you will probably run into some errors. As a quick fix open Finder then press ```cmd-shift-l```. Navigate to the folder named 'Application Support' and delete the folder named 'DeltaClient'. This will completely reset the app and it will go through the first launch sequence again. I appreciate it if you can also create an issue for the error, especially if it persists because it may also be affecting other users. All issues are appreciated no matter how minor.

## Metrics

Here's how the client currently perfomrs when run on my 2020 dual-core Intel i5 MacBook Air with 8gb of ram;

- launch time: 0.85s avg
  - vanilla minecraft: 40s (47x slower)
- first launch time: 35s avg
  - highly dependent on internet speed
- ram usage on home screen: 40mb avg
  - about the same as vanilla minecraft
- ram usage in game: just under 100mb
- time taken to join server: 0.4s on a regular survival world
  - vanilla minecraft takes around 2-3s
  - Delta Client currently only renders one chunk so it's a pretty unfair comparison
- app size: 5.2mb

## Features

- [ ] Networking
  - [x] Basic networking
  - [x] Server list ping
  - [x] Encryption (for non-offline mode servers)
    - [x] Mojang accounts
    - [ ] Microsoft accounts
  - [ ] LAN servers
- [x] Basic config system
  - [ ] Multi-accounting
- [ ] Command-based interface
  - [x] Basic structure
  - [x] Chat command
  - [x] Tab list command
  - [ ] Action commands
  - [ ] Movement commands
- [ ] Rendering
  - [ ] World
    - [x] Basic block rendering
    - [x] Basic chunk rendering
    - [x] Block culling
    - [x] Block models
    - [x] Multipart structures (e.g. fences)
    - [x] Multiple chunks
    - [ ] Animated textures (e.g. lava)
    - [ ] Fluids (lava and water)
    - [ ] Block entities (e.g. chests)
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
  - [ ] Particles
    - [ ] Basic particle system
    - [ ] Block break particles
    - [ ] Ambient particles
    - [ ] Hit particles
    - [ ] Particles from server
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

## Command Interface

Currently the client gives you the option to join a world in commands mode.

These are NOT commands in the traditional minecraft sense (e.g. ```/kill``` and ```/time set day```). They are basic commands that let you interact with the server.

More commands will probably be added later.

Actually, I might just disable these soon, they're pretty useless.

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

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/server-list.png?raw=true)

#### Edit Server List

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/edit-server-list.png?raw=true)

#### Current rendering (only one chunk)

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/rendering/progress-5.png?raw=true)

#### The same place but in vanilla Minecraft

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/rendering/progress-5-vanilla.png?raw=true)
