//
//  PlayServerView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 19/6/21.
//

import SwiftUI
import DeltaCore

enum PlayState {
  case downloadingTerrain
  case playing
}

struct PlayServerView: View {
  var serverDescriptor: ServerDescriptor
  
  var client: Client
  
  @ObservedObject var state = StateWrapper<PlayState>(initial: .downloadingTerrain)
  
  init(serverDescriptor: ServerDescriptor) {
    self.serverDescriptor = serverDescriptor
    
    do {
      let texturePalette = try AssetManager.default.getBlockTexturePalette()
      let pixlyzerData = StorageManager.default.absoluteFromRelative("pixlyzer-data/blocks.json")
      let blockModels = AssetManager.default.vanillaAssetsDirectory.appendingPathComponent("minecraft/models/block")
      let blockPalette = try BlockPalette.parse(
        fromPixlyzerDataAt: pixlyzerData,
        withBlockModelDirectoryAt: blockModels,
        andTexturesFrom: texturePalette)
      
      client = Client(blockPalette: blockPalette)
      client.eventBus.registerHandler(handleClientEvent)
      try client.join(serverDescribedBy: serverDescriptor, with: OfflineAccount(username: "epicboi69"))
    } catch {
      fatalError("whoops: \(error)")
    }
  }
  
  func handleClientEvent(_ event: Event) {
    switch event {
      case _ as TerrainDownloadCompletionEvent:
        state.update(to: .playing)
      default:
        break
    }
  }
  
  var body: some View {
    Group {
      switch state.current {
        case .downloadingTerrain:
          Text("Downloading terrain..")
        case .playing:
          MetalView(client: client)
      }
    }
  }
}
