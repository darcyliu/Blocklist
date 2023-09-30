//
//  StatusView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import CallKit

struct StatusView: View {
    @State var statuLabel = "Unknown";
    var body: some View {
        VStack {
            Text("Call Blocker: \(statuLabel)")
            Button("Open Settings") {
                CXCallDirectoryManager.sharedInstance.openSettings() { (error) in
                    
                }
            }
        }
        .onAppear {
            Task {
                do {
                    let status = try await CXCallDirectoryManager.sharedInstance.enabledStatusForExtension(withIdentifier: "net.macspot.lma.caller")
                    DispatchQueue.main.async {
                        if status == .enabled {
                            statuLabel = "Enabled ✅"
                        } else {
                            statuLabel = "Disabled ❌"
                        }
                    }
                } catch {
                    let error = error as NSError
                    print(error)
                }
            }
        }
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView()
    }
}
