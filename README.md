# Minecraft Delta Client - Changing the meaning of speed

> An open source rewrite of Minecraft Java Edition written in Swift for macOS

## Tl;dr

This client is not at all useable yet. If you're looking for a client to use to play Minecraft today, then this is not for you. But hopefully one day it does get to a useable state.

## Disclaimer

**I am NOT responsible for anti-cheat bans, the client has not been thoroughly tested yet and is still deep in development.**

## Overview

The main focus of this project is to create a highly efficient Java Edition compatible client written in Swift for macOS. Using Swift means that in the future the client may be able to run on iOS, iPadOS and maybe tvOS. This would allow playing on Java Edition servers, on platforms normally limited to Bedrock Edition.

## Contributing

At the moment I am not accepting contributions to this repository. This is still my personal project and I probably won't accept contributions until it gets to a more complete state.

## Discord [![Discord](https://img.shields.io/discord/851058836776419368.svg?label=&logo=discord&logoColor=ffffff&color=5C5C5C&labelColor=6A7EC2)](https://discord.gg/xZPyDbmR6k)

If you need help with something, want to talk with me or just like the project enough, feel free to join the community on [Discord](https://discord.gg/xZPyDbmR6k)

## Metrics

Here's how the client currently performs when run on my 2020 dual-core Intel i5 MacBook Air with 8gb of ram (yeah it's not powerful whatsoever);

- launch time: 0.85s avg
  - vanilla minecraft: 40s (47x slower)
- first launch time: 35s avg
  - highly dependent on internet speed
- ram usage on home screen: 40mb avg
  - about the same as vanilla minecraft
- ram usage in game: just under 100mb
- app size: 5.2mb

## Features

- [ ] Networking
  - [x] Basic networking
  - [x] Server list ping
  - [x] Encryption (for non-offline mode servers)
    - [x] Mojang accounts
    - [ ] Microsoft accounts
  - [ ] LAN server detection
- [x] Basic config system
  - [x] Multi-accounting
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
    - [ ] Lighting
    - [ ] Animated textures (e.g. lava)
    - [ ] Translucency
    - [ ] Fluids (lava and water)
    - [ ] Block entities (e.g. chests)
    - [x] Chunk culling
  - [ ] HUD
    - [ ] Basic text
    - [ ] Chat
    - [ ] F3-style stuff
    - [ ] Bossbars
    - [ ] Scoreboard
    - [ ] Health, hunger and experience
  - [ ] Items (like in the inventory and hotbar)
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
- [ ] Physics
  - [x] Physics loop
  - [x] Input system
  - [ ] Collision system

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

As DeltaClient is still in development it is expected that you will probably run into some errors. Here are the basic troubleshooting steps you should take if you run into any errors;

1. Open Finder then press ```cmd-shift-g``` and go to the following path ```~/Library/Containers/com.stackotter.delta-client/Data/Library```
2. Delete the folder named ```Application Support```. This completely resets the app

I appreciate it if you can also create an issue for the error, especially if it persists because it may also be affecting other users. All issues are appreciated no matter how minor.

## Screenshots

#### Server list

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/server-list.png?raw=true)

#### Current rendering (it has progressed from here but i am yet to update the screenshots)

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/rendering/progress-5.png?raw=true)

#### The same place but in vanilla Minecraft

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/rendering/progress-5-vanilla.png?raw=true)

#### An initial test of 10 render distance

![alt text](https://github.com/stackotter/minecraft-swift-edition/blob/main/screenshots/rendering/initial-10-view-distance-test.png?raw=true)

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
