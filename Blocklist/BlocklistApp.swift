//
//  BlocklistApp.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import CallKit
import PhoneBook

@main
struct BlocklistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject var hudState = HUDState()
    
    let phonebook = PhoneBookManager.sharedInstance()
    var body: some Scene {
        WindowGroup {
            ContentView()
//                .hud(isPresented: $hudState.isPresented) {
//                    Label(hudState.title, systemImage: hudState.systemImage)
//                }
                .modifier(HUDModifier())
                .environmentObject(hudState)
                .environment(\.managedObjectContext, phonebook.context())
            
        }.onChange(of: scenePhase) { (newScenePhase) in
            switch newScenePhase {
            case .active:
                // clean the temporary files
                if let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let enumerator = FileManager.default.enumerator(at: documentsPathURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    while let file = enumerator?.nextObject() {
                        do{
                            try FileManager.default.removeItem(at: file as! URL)
                        } catch {
                            print(error)
                        }
                    }
                }
                
                break
            case .inactive:
                break
            case .background:
                PhoneBookManager.sharedInstance().saveContext()
                PhoneBookManager.sharedInstance().exportAllCallers()
                PhoneBookManager.sharedInstance().removeAllDeletedRecords()
                
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
                        print(error.localizedDescription)
                        NotificationScheduler.scheduleNotification(title: "Call Directory Reload Error", body: "\(message)(\(error.localizedDescription))" , delay: 1)
                    } else {
                        print("Reload succeed.")
                        //NotificationScheduler.scheduleNotification(title: "Call Directory Reload succeed", body: "Done", delay: 1)
                    }
                })
                break
            @unknown default:
                break
            }
        }
    }
}
