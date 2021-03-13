//
//  ViewState.swift
//  Minecraft
//
//  Created by Rohan van Klinken on 26/12/20.
//

import Foundation

class ViewState: ObservableObject {
  @Published var state: ViewStateEnum
  
  enum ViewStateEnum {
    case playing(withRendering: Bool, serverInfo: ServerInfo)
    case serverList(serverList: ServerList)
  }
  
  init(initialState: ViewStateEnum) {
    self.state = initialState
  }
  
  func updateServerList(newServerList: ServerList) {
    state = .serverList(serverList: newServerList)
  }
  
  func playServer(withInfo info: ServerInfo, withRendering: Bool) {
    state = .playing(withRendering: withRendering, serverInfo: info)
  }
}
