//
//  CallDirectoryView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers
import PhoneBook

extension PBRecord: Identifiable {
    public var id: String {
        String(number)
    }
}

private struct CallersListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var hud: HUDState
    var fetchRequest: FetchRequest<PBRecord>
    var searchText = ""
    var selectedCategory = 0
    var body: some View {
        if items.count > 0 {
            List {
                Section {
                    ForEach(items) { item in
                        NavigationLink {
                            CallerDetailView(item: item)
                        } label: {
                            HStack {
                                Image(systemName: item.blocked ? "bell.slash.circle":"person.text.rectangle")
                                    .imageScale(.large)
                                    .foregroundColor(.accentColor)
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("\(String(item.number))").font(.title3)
                                    }
                                    HStack {
                                        Text("\(item.name ?? "")")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 4)
                                            .background(.ultraThickMaterial)
                                            .cornerRadius(5)
                                        Spacer()
                                        Text("\(item.created!, formatter: itemFormatter)").font(.footnote)
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
                footer: {
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
                            Text(" to add a caller.")
                        }
                    }
                }
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding()
                
                Text("To turn on Call Blocker on your phone:").padding()
                
                CallBlockerInstructionsView()
            }
        }
    }
    private var items: FetchedResults<PBRecord> {
        fetchRequest.wrappedValue
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            //offsets.map { items[$0] }.forEach(viewContext.delete)
            
            offsets.map { items[$0] }.forEach { item in
                item.removed = true
            }

            do {
                try viewContext.save()
                hud.show(content: Label(selectedCategory == 0 ? "Blocked number deleted.":"ID number deleted.", systemImage: "checkmark.circle.fill"))
            } catch {
                let nsError = error as NSError
                hud.show(content: Label(nsError.localizedDescription, systemImage: "xmark.circle.fill"))
            }
        }
    }
}

struct CallDirectoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var hud: HUDState

    @State private var searchText = ""
    @State private var selectedCategory = 0
    @State private var showAddNumberView = false
    @State private var name = ""
    @State private var phoneNumber = ""

    @State private var showHelpGuide = false
    @State private var showFileImporter = false
    
    private func makeFetchRequest() -> FetchRequest<PBRecord> {
        let request:NSFetchRequest<PBRecord> =  PhoneBookManager.sharedInstance().fetchRequestForCallers() as! NSFetchRequest<PBRecord>
        let blockedPredicate = selectedCategory == 0 ? NSPredicate(format: "blocked == YES"):NSPredicate(format: "blocked == NO")
        
        var predicates = [blockedPredicate, NSPredicate(format: "removed == NO")];
        
        if searchText.isEmpty {
            //
        } else {
            let matchPredicate = NSPredicate(format: "number CONTAINS %@ OR name CONTAINS[c] %@", searchText, searchText)
            predicates.append(matchPredicate)
        }
        let predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        request.predicate = predicate
        return FetchRequest(fetchRequest: request)
    }

    var body: some View {
        NavigationView {
            CallersListView(fetchRequest: makeFetchRequest(), searchText: searchText, selectedCategory: selectedCategory)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: toggleShowAddNumberView) {
                            Label("Add Item", systemImage: "plus.circle")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Menu {
                            Button {
                                showFileImporter = true
                            } label: {
                                Label("Import Call Directory", systemImage: "square.and.arrow.down")
                            }
                            Button {
                                exportActionSheet()
                            } label: {
                                Label("Export Call Directory", systemImage: "square.and.arrow.down")
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
                    
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Picker("Category", selection: $selectedCategory) {
                                Text("Blocked").tag(0)
                                Text("Identification").tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Look for ...")
                .navigationTitle(selectedCategory==0 ? "Blocked":"Identification")
                .onChange(of: searchText) { newValue in
                    updatePredicate()
                }
                .onChange(of: selectedCategory) { newValue in
                    updatePredicate()
                }
                .alert("Add A New Phone Number", isPresented: $showAddNumberView) {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                    if selectedCategory == 0 {
                        Button("Block this Number", role: .destructive) {
                            addItem()
                        }
                    } else {
                        Button("Add to Identification", role: .destructive) {
                            addItem()
                        }
                        Button("Cancel", role: .cancel) {
                            
                        }
                    }
                }
                .sheet(isPresented: $showHelpGuide) {
                    CallBlockerGuideView()
                }
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [UTType(filenameExtension: "blc")!]) { result in
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
    
    private func updatePredicate() {
        
    }
    
    private func addItem() {
        withAnimation {
            let cleanPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .joined()
            let pn = Int64(cleanPhoneNumber) ?? 0
            if pn <= 0 {
                hud.show(content:  Label("Invalid phone number.", systemImage: "xmark.circle.fill").foregroundColor(.red))
                return
            }
            let records = PhoneBookManager.sharedInstance().getRecordsForPhone(NSNumber(value: pn))
            if records.count > 0 {
                hud.show(content: Label("Phone number exists.", systemImage: "xmark.circle.fill"))
            } else {
                if name.isEmpty {
                    if selectedCategory == 0 {
                        name = "Spam"
                    } else {
                        name = "Someone"
                    }
                }
                let record = PBRecord(context: viewContext)
                record.created = Date()
                record.updated = Date()
                record.name = name
                record.blocked = selectedCategory == 0
                record.number = pn
                record.removed = false
                do {
                    try viewContext.save()
                    hud.show(content: Label(selectedCategory == 0 ? "Blocked number added.":"ID number added.", systemImage: "checkmark.circle.fill"))
                } catch {
                    let nsError = error as NSError
                    hud.show(content: Label(nsError.localizedDescription, systemImage: "xmark.circle.fill"))
                }
            }

            name = ""
            phoneNumber = ""
        }
    }
    
    private func toggleShowAddNumberView() {
        showAddNumberView.toggle()
    }
    
    private func exportActionSheet() {
        guard let url = PhoneBookManager.sharedInstance().exportCallers() else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        let scenes = UIApplication.shared.connectedScenes
        let windowScenes = scenes.first as? UIWindowScene
        let window = windowScenes?.windows.first
        window?.rootViewController?.present(activityVC, animated: true, completion: nil)
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

struct CallDirectoryView_Previews: PreviewProvider {
    static var previews: some View {
        CallDirectoryView()
    }
}
