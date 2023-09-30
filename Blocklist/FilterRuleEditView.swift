//
//  FilterRuleEditView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import PhoneBook

struct FilterRuleEditView: View {    
    @Binding var filterType: PBRuleType
    @Binding var filterPattern: String
    @Binding var filterAction:PBRuleAction
    @Binding var regexModeEnabled: Bool
    
    // disable based on editMode may cause "AttributeGraph: cycle detected through attribute" issue
    // we are going to enable/disable the form elements individually as a workaround.
    var isEditing = false
    var body: some View {
        Form {
            Section(header: Text("Filter Rule")) {
                Picker(selection: $filterType) {
                    Text("Any").tag(PBRuleType.any)
                    Text("Sender Name or Number").tag(PBRuleType.sender)
                    Text("Message Body").tag(PBRuleType.message)
                } label: {
                    Text("**Filter Type**")
                }.disabled(!isEditing)
                                            
                Picker(selection: $filterAction) {
                    //Text("None").tag(PBRuleAction.none)
                    Text("Allow").tag(PBRuleAction.allow)
                    Text("Junk").tag(PBRuleAction.junk)
                    Text("Transaction").tag(PBRuleAction.transaction)
                    Text("Promotion").tag(PBRuleAction.promotion)
                } label: {
                    Text("**Action**")
                }.disabled(!isEditing)
                
                HStack {
                    Text("**Match**")
                    TextField("Pattern", text: $filterPattern)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .lineLimit(5)
                        .disabled(!isEditing)
                }
                
//                Toggle(isOn: $regexModeEnabled) {
//                    Text("Regular Expression Mode")
//                }
            }
        }
    }
}

struct FilterRuleEditView_Previews: PreviewProvider {
    static var previews: some View {
        FilterRuleEditView(filterType: .constant(PBRuleType.any),
                           filterPattern: .constant(""),
                           filterAction: .constant(PBRuleAction.none),
                           regexModeEnabled: .constant(false))
    }
}
