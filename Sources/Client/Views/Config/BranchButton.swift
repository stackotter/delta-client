import SwiftUI

struct BranchButton: View {
    
    @EnvironmentObject var updater: Updater
    
    let branch: String
    
    var body: some View {
        Button(branch) {
            updater.unstableBranch = branch
        }
    }
}
