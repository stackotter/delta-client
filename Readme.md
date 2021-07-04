# Minecraft Delta Client - Changing the meaning of speed

An open source rewrite of Minecraft Java Edition written in Swift for macOS.

## Tl;dr

This client is not at all useable yet. If you're looking for a client to use to play Minecraft today, then this is not for you. But hopefully one day it does get to a useable state.

## Disclaimer

**I am NOT responsible for anti-cheat bans, the client has not been thoroughly tested yet and is still deep in development.**

## Overview

The main focus of this project is to create a highly efficient Java Edition compatible client written in Swift for macOS. Using Swift means that in the future the client may be able to run on iOS, iPadOS and maybe tvOS. This would allow playing on Java Edition servers, on platforms normally limited to Bedrock Edition.

## Contributing

At the moment I am not accepting contributions to this repository. This is still my personal project and I probably won't accept contributions until it gets to a more complete state.

## Discord [![Discord](https://img.shields.io/discord/851058836776419368.svg?label=&logo=discord&logoColor=ffffff&color=5C5C5C&labelColor=6A7EC2)](https://discord.gg/xZPyDbmR6k)

If you want to have a say in the development of the client or have any questions, feel free to join the community on [Discord](https://discord.gg/xZPyDbmR6k)

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
2. Unzip the download (if it doesn't automatically do so) and open the app inside
3. You will get a security alert, click ok
4. Right click the app and click open
5. You should get another pop-up, click 'Open'
6. Wait for it to download and process the required assets (this only has to happen once and should take around 40s with a mediocre internet speed)
7. You can move DeltaCore to your Applications folder for ease of use if you want

## Usage

To start a test server download a 1.16.1 server jar from [here](https://mcversions.net/download/1.16.1). Then in Terminal type `java -jar ` and then drag the download .jar file onto the terminal window and then hit enter. Wait for the server to start up. Now add a new server with the ip 127.0.0.1 in DeltaCore and you should be able to connect to it. The Minecraft server jar does take up a lot of ram and cpu so people have reported that that has made their fans really loud. It is most likely not DeltaCore making the fans spin like a helicopter.

To run DeltaCore from terminal you can run `open -a "DeltaCore"` in terminal. This allows you to see the pretty coloured logs as the app is running :)

## Troubleshooting

As DeltaCore is still in development it is expected that you will probably run into some errors. Here are the basic troubleshooting steps you should take if you run into any errors;

First, create an issue on this GitHub repository for the error. To find the logs hit cmd+shift+g and enter in `~/Library/Containers/dev.stackotter.delta-client/Data/Library/Application Support/log`. The relevant logs are likely in `latest.log` in that folder.

If the error is in app startup you can also try running `rm ~/Library/Containers/dev.stackotter.delta-client/Data/Library/Application Support/.haslaunched` in Terminal to perform a fresh install. Next time the app starts it will backup all your current configuration before performing the fresh install.

## Screenshots

![alt text](https://github.com/stackotter/delta-client/blob/main/Screenshots/ui.png?raw=true)

![alt text](https://github.com/stackotter/delta-client/blob/main/Screenshots/from-ground.png?raw=true)

![alt text](https://github.com/stackotter/delta-client/blob/main/Screenshots/aerial.png?raw=true)

![alt text](https://github.com/stackotter/delta-client/blob/main/Screenshots/hypixel.png?raw=true)
