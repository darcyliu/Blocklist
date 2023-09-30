//
//  MessageFilterInstructionsView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI

struct MessageFilterInstructionsView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("1. **OPEN** the")
                Button{
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } label: {
                    Label("**Settings**", systemImage: "gear.circle")
                        .cornerRadius(5)
                }
                Text("app")
            }

            HStack {
                Text("2. **TAP**")
                Image(systemName: "message.circle").foregroundColor(Color.blue)
                Text("Messages")
            }

            HStack {
                Text("3. **TAP** _Unknown & Spam_")
            }

            HStack {
                Text("4. **SELECT**")
                Image(systemName: "checkmark.circle").foregroundColor(Color.blue)
                Text("**Blocklist**")
            }
        }
    }
}

struct MessageFilterInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        MessageFilterInstructionsView()
    }
}
