//
//  CallerDetailView.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import SwiftUI
import PhoneBook

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

struct CallerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.editMode) private var editMode
    @State private var name = ""
    @State var item:PBRecord
    var body: some View {
        Form {
             if editMode?.wrappedValue.isEditing == true {
                 TextField("Name", text: $name)
                 Text("You can only edit the name associated with this phone number (\(String(item.number))).").font(.footnote)
             } else {
                 Text("**Name:** \(name)")
                 Text("**Phone Number:** \(String(item.number))")
                 Text("Added at \(item.created!, formatter: itemFormatter)")
             }
        }
        .navigationTitle(item.blocked ? "Blocked":"Identification")
        .animation(nil, value: editMode?.wrappedValue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .onChange(of: editMode?.wrappedValue) { newValue in
                        if newValue?.isEditing == true {
                            
                        } else {
                            do {
                                item.name = name
                                try viewContext.save()
                            } catch {
                                
                            }
                        }
                }
            }
        }
        .task {
            name = item.name ?? "Unknown"
        }
    }
}

struct CallerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CallerDetailView(item:PBRecord())
    }
}
