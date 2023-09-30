//
//  CallBlockerInstructionsView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import CallKit
struct CallBlockerInstructionsView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("1. **OPEN** the")
                Image(systemName: "gear.circle").foregroundColor(Color.blue)
                Text("**Settings**")
                Text("app")
            }

            HStack {
                Text("2. **TAP**")
                Button{
                    CXCallDirectoryManager.sharedInstance.openSettings() { (error) in }
                } label: {
                    Label("**Phone**", systemImage: "phone.circle")
                        .cornerRadius(5)
                }
            }

            HStack {
                Text("3. **TAP** _Call Blocking & Identification_")
            }

            HStack {
                Text("4. **TURN ON**")
                Image(systemName: "switch.2").foregroundColor(Color.blue)
                Text("**Blocklist**")
            }
        }
    }
}

struct CallBlockerInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        CallBlockerInstructionsView()
    }
}
