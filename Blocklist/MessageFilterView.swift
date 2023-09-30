//
//  MessageFilterView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import CoreData
import IdentityLookup
import UniformTypeIdentifiers
import PhoneBook

extension PBRule: Identifiable {
    func imageName() -> String {
        switch (UInt(self.type)) {
            case PBRuleType.sender.rawValue:
                return "number.circle"
            case PBRuleType.message.rawValue:
                return "message.circle"
            default:
                return "ellipsis.message"
        }
    }
    func actionName() -> String {
        switch (UInt(self.action)) {
            case PBRuleAction.allow.rawValue:
                return "Allow"
            case PBRuleAction.junk.rawValue:
                return "Junk"
            case PBRuleAction.promotion.rawValue:
                return "Promotion"
            case PBRuleAction.transaction.rawValue:
                return "Transaction"
            default:
                return "None"
        }
    }
    
    func actionColor() -> Color {
        switch (UInt(self.action)) {
            case PBRuleAction.allow.rawValue:
                return Color.green
            case PBRuleAction.junk.rawValue:
                return Color.red
            case PBRuleAction.promotion.rawValue:
                return Color.blue
            case PBRuleAction.transaction.rawValue:
                return Color.blue
            default:
                return Color.yellow
        }
    }
}

private let fetchRequest: NSFetchRequest<PBRule> = {
    let request:NSFetchRequest<PBRule> =  PhoneBookManager.sharedInstance().fetchRequestForRules() as! NSFetchRequest<PBRule>
    return request
}()

struct MessageFilterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hud: HUDState
    @FetchRequest(fetchRequest: fetchRequest)
    private var items: FetchedResults<PBRule>
    @State private var showAddView = false
    @State private var searchText = ""
    
    @State var filterType: PBRuleType = PBRuleType.any
    @State var filterPattern: String = ""
    @State var filterAction:PBRuleAction = PBRuleAction.junk
    @State var regexModeEnabled = false
    
    @State private var showHelpGuide = false
    @State private var showFileImporter = false
    var body: some View {
        NavigationView {
            filterList
            .navigationTitle("Message Filter")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Look for ...")
            .onChange(of: searchText) { newValue in
                updatePredicate()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: toggleAddView) {
                        Label("Add Item", systemImage: "plus.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showFileImporter.toggle()
                        } label: {
                            Label("Import Filter Rules", systemImage: "square.and.arrow.down")
                        }
                        Button {
                            exportActionSheet()
                        } label: {
                            Label("Export Filter Rules", systemImage: "square.and.arrow.down")
                        }
                        Divider()
                        Button {
                            showHelpGuide.toggle()
                        } label: {
                            Label("Help", systemImage: "questionmark.circle")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddView) {
                NavigationView {
                    FilterRuleEditView(filterType: $filterType,
                                       filterPattern: $filterPattern,
                                       filterAction: $filterAction,
                                       regexModeEnabled: $regexModeEnabled,
                                    isEditing: true)
                    .navigationBarTitle("Add New Rule")
                    .toolbar {
                        ToolbarItemGroup(placement: .confirmationAction) {
                            Button("Done") {
                                addItem()
                                showAddView = false
                            }
                        }

                        ToolbarItemGroup(placement: .cancellationAction) {
                            Button("Cancel") {
                                showAddView = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showHelpGuide) {
                MessageFilterGuideView()
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType(filenameExtension: "blm")!]) { result in
                switch result {
                case .success(let url):
                    do {
                        print(url)
                        PhoneBookManager.sharedInstance().importFile(url)
                        hud.show(content: Label("Import file completed.", systemImage: "checkmark.circle.fill"))
                    }
                    break
                case .failure(let error):
                    hud.show(content: Label(error.localizedDescription, systemImage: "xmark.circle.fill"))
                    break
                }
            }
        }
    }
    @ViewBuilder
    private var filterList: some View {
        if items.count > 0 {
            List {
                Section {
                    ForEach(items) { item in
                        NavigationLink {
                            FilterRuleDetailView(item: item)
                        } label: {
                            HStack {
                                Image(systemName: item.imageName())
                                    .imageScale(.large)
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading) {
                                    Text("\(item.pattern ?? "" )").font(.title3)
                                    HStack {
                                        Text("\(item.actionName())")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 4)
                                            .background(item.actionColor())
                                            .cornerRadius(5)
                                    }
                                }
                            }
                            
                        }
                    }
                    .onDelete(perform: deleteItems)
                } footer: {
                    Text("Total: \(items.count)")
                }
            }.listStyle(.insetGrouped)
        } else {
            VStack {
                VStack {
                    Text("No record.").font(.title2).bold().padding()
                    
                    if searchText.isEmpty {
                        HStack(spacing: 0) {
                            Text("Tap ")
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                            Text(" to add a rule.")
                        }
                    }
                }
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding()
                
                Text("To turn on Message Filter on your phone:").padding()
                MessageFilterInstructionsView()
            }
        }
    }
    
    private func updatePredicate() {
        let predicate = searchText.isEmpty ? nil: NSPredicate(format: "pattern CONTAINS[c] %@", searchText)
        
        items.nsPredicate = predicate
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
                hud.show(content: Label("Rule deleted.", systemImage: "checkmark.circle.fill"))
            } catch {
                let nsError = error as NSError
                hud.show(content: Label(nsError.localizedDescription, systemImage: "xmark.circle.fill"))
            }
        }
    }
    
    private func toggleAddView() {
        showAddView.toggle()
    }

    private func addItem() {
        withAnimation {
            if filterPattern.isEmpty || filterPattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
                hud.show(content:  Label("Empty rule pattern.", systemImage: "xmark.circle.fill").foregroundColor(.red))
                return
            }
            let rules = PhoneBookManager.sharedInstance().getRulesForPattern(filterPattern)
            if rules.count > 0  {
                hud.show(content: Label("Rule pattern exists.", systemImage: "xmark.circle.fill"))
            } else {
                let rule = PBRule(context: viewContext)
                rule.created = Date();
                rule.pattern = filterPattern
                rule.type = Int16(filterType.rawValue)
                rule.action = Int16(filterAction.rawValue)
                do {
                    try viewContext.save()
                    hud.show(content: Label("Rule added.", systemImage: "checkmark.circle.fill"))
                } catch {
                    let nsError = error as NSError
                    hud.show(content: Label(nsError.localizedDescription, systemImage: "xmark.circle.fill"))
                }
            }
            
            filterPattern = ""
            filterType = .any
            filterAction = .junk
        }
    }
    
    private func exportActionSheet() {
        guard let url = PhoneBookManager.sharedInstance().exportRules() else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        window?.rootViewController?.present(activityVC, animated: true, completion: nil)
    }
}

struct MessageFilterView_Previews: PreviewProvider {
    static var previews: some View {
        MessageFilterView()
    }
}
