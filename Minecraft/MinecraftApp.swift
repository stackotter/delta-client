//
//  MinecraftApp.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 10/12/20.
//

import SwiftUI

@main
struct MinecraftApp: App {
  let minecraftFolder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("minecraft")
  var config: Config
//  let serverList = ServerList(withServers: [
//    Server(name: "Localhost Spigot", host: "127.0.0.1", port: 25565),
//    Server(name: "Localhost Bungee", host: "127.0.0.1", port: 25577),
//    Server(name: "HyPixel", host: "mc.hypixel.net", port: 25565)
//    // TODO: figure out why mineplex makes energy usage skyrocket in server list
//    //   Server(name: "MinePlex", host: "us.mineplex.com", port: 25565),
//    // TODO: figure out SRV records:
//    //   Server(name: "PVPWars", host: "play.pvpwars.net", port: 25565)
//  ])
  
  init() {
    // TODO: error handle minecraft folder not existing
    config = Config.from(minecraftFolder: minecraftFolder)
  }
  
  var body: some Scene {
    WindowGroup {
      MainView(serverList: config.serverList)
    }
  }
}
