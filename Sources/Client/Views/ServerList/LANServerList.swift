import SwiftUI
import DeltaCore

struct LANServerList: View {
  @ObservedObject var lanServerEnumerator: LANServerEnumerator
  
  var body: some View {
    if !lanServerEnumerator.pingers.isEmpty {
      ForEach(lanServerEnumerator.pingers, id: \.self) { pinger in
        NavigationLink(destination: ServerDetail(pinger: pinger)) {
          ServerListItem(pinger: pinger)
        }
      }
    } else {
      Text(lanServerEnumerator.hasErrored ? "LAN scan failed" : "scanning LAN...").italic()
    }
  }
}
