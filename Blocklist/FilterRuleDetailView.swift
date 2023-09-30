//
//  FilterRuleDetailView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import PhoneBook

struct FilterRuleDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    @EnvironmentObject private var hud: HUDState
    
    @State private var name = ""
    @State var item:PBRule
    
    @State var filterType: PBRuleType = PBRuleType.any
    @State var filterPattern: String = ""
    @State var filterAction:PBRuleAction = PBRuleAction.junk
    @State var regexModeEnabled = false
    var body: some View {
        FilterRuleEditView(filterType: $filterType,
                           filterPattern: $filterPattern,
                           filterAction: $filterAction,
                           regexModeEnabled: $regexModeEnabled,
                           isEditing: editMode?.wrappedValue.isEditing == true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                .onChange(of: editMode?.wrappedValue) { newValue in
                    if newValue?.isEditing == true {
                         
                    } else {
                       updateRule()
                    }
                }
            }
        }
        .task {
            filterType = PBRuleType(rawValue: UInt(item.type)) ?? PBRuleType.any
            filterAction = PBRuleAction(rawValue: UInt(item.action)) ?? PBRuleAction.none
            filterPattern = item.pattern ?? ""
        }
    }
    
    private func updateRule() {
        withAnimation {
            do {
                if filterPattern.isEmpty {
                    hud.show(content: Label("Pattern cannot be empty.", systemImage: "xmark.circle.fill"))
                    return
                }
                item.pattern = filterPattern
                item.type = Int16(filterType.rawValue)
                item.action = Int16(filterAction.rawValue)
                try viewContext.save()
                
                hud.show(content: Label("Filter rule updated.", systemImage: "checkmark.circle.fill"))
            } catch {
                
            }
        }
    }
}

struct FilterRuleDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FilterRuleDetailView(item: PBRule())
    }
}
