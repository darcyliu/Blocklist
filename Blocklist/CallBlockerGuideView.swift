//
//  CallBlockerGuideView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import CallKit

struct CallBlockerGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    //@Environment(\.hudState) var hud
    @EnvironmentObject private var hud: HUDState
    @State var statusLabel = "Unknown";
    var body: some View {
        VStack {
            Text("Call Blocker Extension Status: \(statusLabel)")
        }
        .onAppear {
            Task {
                do {
                    let status = try await CXCallDirectoryManager.sharedInstance.enabledStatusForExtension(withIdentifier: "net.macspot.lma.caller")
                    DispatchQueue.main.async {
                        if status == .enabled {
                            statusLabel = "Enabled ✅"
                        } else {
                            statusLabel = "Disabled ❌"
                        }
                    }
                } catch {
                    let error = error as NSError
                    print(error)
                }
            }
        }
        
        Text("To turn on Call Blocker on your phone:").padding()
        
        CallBlockerInstructionsView()

        Button{
            CXCallDirectoryManager.sharedInstance.openSettings() { (error) in
                
            }
        } label: {
            Label("Click me to open **Settings**", systemImage: "gear.circle")
                .padding(5)
                .cornerRadius(5)
        }
        .padding(40)
        
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("I got it.")
                .font(Font.headline)
                .frame(minWidth: 200, maxWidth: 280)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(.blue)
    }
}

struct CallBlockerGuideView_Previews: PreviewProvider {
    static var previews: some View {
        CallBlockerGuideView()
    }
}
