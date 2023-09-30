//
//  ContentView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import PhoneBook

struct ContentView: View {
    @EnvironmentObject private var hud: HUDState
    var body: some View {
        TabView {
            CallDirectoryView()
            .tabItem {
                Label("Call Blocker", systemImage: "phone.fill")
            }
            MessageFilterView(filterType: .any)
            .tabItem {
                Label("Message Filter", systemImage: "message.fill")
            }
//            StatusView()
//            .tabItem {
//                Label("Info", systemImage: "info.circle.fill")
//            }
        }
        .onOpenURL { incomingURL in
            handleIncomingURL(incomingURL)
        }
    }
    private func handleIncomingURL(_ url: URL) {
        PhoneBookManager.sharedInstance().importFile(url)
        hud.show(content: Label("Import file completed.", systemImage: "checkmark.circle.fill"))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
