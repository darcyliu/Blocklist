//
//  HUDView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI

final class HUDState: ObservableObject {
    @Published var isPresented: Bool = false
    public var content: any View = EmptyView()
    
    public func show(content: any View) {
        self.content = content
        withAnimation {
            isPresented = true
        }
    }
}

struct HUDModifier: ViewModifier {
    @EnvironmentObject private var hudState: HUDState
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            Color.clear
            content
        }.overlay(alignment: .top) {
            if hudState.isPresented {
                HUDView {
                    AnyView(hudState.content)
                }
                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                        removal: .move(edge: .top).combined(with: .opacity)))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            hudState.isPresented = false
                        }
                    }
                }
                .onTapGesture {
                    withAnimation {
                        hudState.isPresented = false
                    }
                }
                .zIndex(UIWindow.Level.statusBar.rawValue + 1)
            }
        }
    }
}

struct HUDView<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        content
            .padding(15)
            .background(
                Capsule()
                    .foregroundColor(Color.white)
                    .shadow(color: Color(.black).opacity(0.25), radius: 10, x: 0, y: 5)
            )
            //.background(.ultraThinMaterial, in: Capsule())
            //.compositingGroup()
            //.shadow(color: Color(.black).opacity(0.25), radius: 10, x: 0, y: 5)
    }
}

struct HUDView_Previews: PreviewProvider {
    static var previews: some View {
        HUDView(content: {Text("Hello")})
    }
}

