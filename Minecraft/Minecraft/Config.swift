//
//  Config.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 14/12/20.
//

import Foundation
import AppKit
import Network

// TODO: Get this working under the sandbox
struct Config {
  var serverList: ServerList
  
  static func from(minecraftFolder: URL) -> Config {
    let serverList = loadServerList(minecraftFolder: minecraftFolder)
    loadUserProfile(minecraftFolder: minecraftFolder)
    return Config(serverList: serverList)
  }
  
  static func loadServerList(minecraftFolder: URL) -> ServerList {
    let serversDatURL = minecraftFolder.appendingPathComponent("servers.dat")
    let serversNBT = NBT.fromURL(serversDatURL)
    let serverNBTList = serversNBT.root.nbtData["servers"] as! [[String: String]]
    var servers: [Server] = []
    for serverNBT in serverNBTList {
      let ip = serverNBT["ip"]!
      let name = serverNBT["name"]!
      
      let server: Server?
      if let url = URL.init(string: "minecraft://\(ip)") {
        if let host = url.host {
          if let port = url.port {
            server = Server(name: name, host: host, port: port)
          } else {
            server = Server(name: name, host: host, port: 25565)
          }
        } else {
          print("server ip has no host?")
          continue
        }
      } else {
        print("invalid server ip: \(ip)")
        continue
      }
      servers.append(server!)
    }
    return ServerList(withServers: servers)
  }
  
  static func loadUserProfile(minecraftFolder: URL) {
    let launcherProfilesURL = minecraftFolder.appendingPathComponent("launcher_profiles.json")
    let json = JSON.fromURL(launcherProfilesURL)
    let selectedUser = json.getJSON(forKey: "selectedUser")
    let accountUUID = selectedUser.getString(forKey: "account")
    let profileUUID = selectedUser.getString(forKey: "profile")
    print(accountUUID)
    print(profileUUID)
  }
}
