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
    @State var reloadStatusLabel = "";
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
        
        Button{
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "net.macspot.lma.caller", completionHandler: { (error) in
                if let error = error as? CXErrorCodeCallDirectoryManagerError {
                    print("Reload error: \(error.localizedDescription)")
                    print("reload failed")
                    var message = ""
                    switch error.code {
                        case .unknown:
                            message = "Unknown"
                        case .noExtensionFound:
                            message = "No extension found"
                        case .loadingInterrupted:
                            message = "Loading tnterrupted"
                        case .entriesOutOfOrder:
                            message = "Entries out of order"
                        case .duplicateEntries:
                            message = "Duplicate entries"
                        case .maximumEntriesExceeded:
                            message = "Maximum entries exceeded"
                        case .extensionDisabled:
                            message = "Extension disabled"
                        case .currentlyLoading:
                            message = "Ccurrently Loading"
                        case .unexpectedIncrementalRemoval:
                            message = "Unexpected incremental removal"
                        @unknown default:
                            message = "Unknown"
                    }
                    reloadStatusLabel = message
                    print(error.localizedDescription)
                } else {
                    print("Reload succeeded.")
                    reloadStatusLabel = "Reload succeeded"
                }
            })
        } label: {
            Label("Reload Call Directory Manually.", systemImage: "arrow.triangle.2.circlepath.circle")
                .padding(5)
                .cornerRadius(5)
        }
        .padding(20)
        
        if !reloadStatusLabel.isEmpty {
            Text("Reload result: \(reloadStatusLabel)")
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
