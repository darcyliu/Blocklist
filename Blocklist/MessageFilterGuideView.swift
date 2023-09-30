//
//  MessageFilterGuideView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI

struct MessageFilterGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        Text("To turn on Message Filter on your phone:").padding()
        MessageFilterInstructionsView()
        
        Button{
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
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

struct MessageFilterGuideView_Previews: PreviewProvider {
    static var previews: some View {
        MessageFilterGuideView()
    }
}
