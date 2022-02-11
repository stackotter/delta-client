# Delta Client - Changing the meaning of speed

[![Discord](https://img.shields.io/discord/851058836776419368.svg?label=&logo=discord&logoColor=ffffff&color=5C5C5C&labelColor=6A7EC2)](https://discord.gg/xZPyDbmR6k)

An open source rewrite of the *Minecraft: Java Edition* client, written in Swift for macOS. Currently Delta Client only supports connecting to 1.16.1 servers.

## Disclaimer

This client is not useable yet. If you're looking for a client to use to play Minecraft today, then this is not for you. However, the plan is that one day it does get to a useable state.

**I am NOT responsible for anti-cheat bans, the client has not been thoroughly tested yet and is still deep in development.**

**This software is not affiliated with Mojang AB, the original developer of Minecraft.**

## Overview

The main focus of this project is to create a highly efficient Java Edition compatible client written in Swift for macOS. Using Swift means that in the future the client may be able to run on iOS, iPadOS and maybe tvOS. This would allow playing on Java Edition servers, on platforms normally limited to Bedrock Edition.

If you want to have a say in the development of the client or have any questions, feel free to join the community on [Discord](https://discord.gg/xZPyDbmR6k).

![alt text](https://github.com/stackotter/delta-client/blob/main/Screenshots/hypixel-1.png?raw=true)

## Installation

1. Visit [the Delta Client website's download page](https://delta.stackotter.dev/downloads) and download the latest unstable build (the stable releases are very outdated).
2. Unzip the downloaded zip archive and open the app inside
3. You will get a security alert, click ok
4. Right click the app in finder and select open
5. You should get another pop-up, click 'Open'
6. Delta Client will now open and start downloading the required assets (this only has to happen once and should take around 40s with a mediocre internet speed)
7. You can move Delta Client to your Applications folder for ease of use if you want

## Building

To build Delta Client you'll first need to install Xcode and the latest version of [swift-bundler](https://github.com/stackotter/swift-bundler). Once you've installed both of those, run the following commands in terminal;

```sh
# Clone Delta Client
git clone https://github.com/stackotter/delta-client
cd delta-client
git checkout dev # choose a different branch if you desire

# Perform a release build, output the .app to the current directory, and show a fancy progress bar in a pop-up window
swift bundler build -c release -o . -p

# If you want to work on it in Xcode
swift bundler generate-xcode-support
# And then open Package.swift with Xcode and you'll be able to build it from Xcode too
```

## Minecraft version support

At the moment the client only supports joining **1.16.1** servers. In the future I plan to support more versions. But not now, as that'd slow down development of more important features because it would create more maintenance work.

Not every version will be perfectly supported but I will try and have the most polished support for the following versions;

- 1.8.9
- the latest speedrunning version (currently 1.16.1 and may be for a while)
- the latest stable version

## Features

- [ ] Networking
  - [x] Basic networking
  - [x] Server list ping
  - [x] Encryption (for non-offline mode servers)
    - [x] Mojang accounts
    - [ ] Microsoft accounts
  - [x] LAN server detection
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
    - [x] Lighting
    - [x] Animated textures (e.g. lava)
    - [x] Translucency
    - [x] Fluids (lava and water)
    - [x] Chunk frustum culling
    - [x] Biome blending (mostly)
    - [ ] Block entities (e.g. chests)
  - [ ] Entities
    - [x] Basic entity rendering (just coloured cubes)
    - [ ] Render entity models
    - [ ] Entity animations
  - [ ] Particles
    - [ ] Basic particle system
    - [ ] Block break particles
    - [ ] Ambient particles
    - [ ] Hit particles
    - [ ] Particles from server
  - [ ] Items (like in the inventory and hotbar)
  - [ ] GUI
    - [ ] Chat
    - [ ] F3-style stuff
    - [ ] Bossbars
    - [ ] Scoreboard
    - [ ] Health, hunger and experience
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
- [ ] Interaction
  - [ ] Block placing
  - [ ] Block breaking
  - [ ] Block entity interaction
  - [ ] Entity interaction

## Contributing

First, please check out the [contributing guidelines](Contributing.md). Then you can checkout the [issues](https://github.com/stackotter/delta-client/issues) for a place to get started. Make sure to leave a comment on the issue you choose, so that people know that someone's already working on it. All changes should be made on the dev branch or a branch created from dev.

## Servers

We now have an official test server made by @ninjadev64! The address is `play.stackotter.dev`. To run it cheaply, the server goes to sleep. To join it click play and you'll get a message telling you that it's starting up. Wait around 10 seconds and then click play again and you should be good to go. Alternatively, you can run your own server on your computer (see below).

To start a test server, download a 1.16.1 server jar from [here](https://mcversions.net/download/1.16.1). Then in Terminal type `java -jar ` and then drag the download .jar file onto the terminal window and then hit enter. Wait for the server to start up. Now add a new server with the address `127.0.0.1` in Delta Client and you should be able to connect to it. Keep in mind the server may use a significant amount of resources and slow down Delta Client.

To run Delta Client from terminal you can run `/path/to/DeltaClient.app/Contents/MacOS/DeltaClient` in terminal. This allows you to see the logs as the app is running.

## Troubleshooting

As Delta Client is still in development it is expected that you will probably run into some errors. Here are the basic troubleshooting steps you should take if you run into any errors;

First, create an issue on GitHub for the error.

If the error is in app startup, you can try running `rm ~/Library/Application Support/dev.stackotter.delta-client/.haslaunched` in Terminal to perform a fresh install. Next time the app starts it will perform a fresh install. Your configuration gets wiped but it is backed up in a zip archive in the same folder as .haslauncher

## More screenshots

![alt text](https://github.com/stackotter/delta-client/blob/main/Screenshots/hypixel-2.png?raw=true)

![alt text](https://github.com/stackotter/delta-client/blob/main/Screenshots/ui.png?raw=true)
