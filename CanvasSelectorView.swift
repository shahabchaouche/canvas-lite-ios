//
//  SwiftUIView.swift
//  CanvasPDFExport
//
//  Created by Shahab on 2024-06-02.
//
import SwiftUI
import CoreData

struct CanvasSelectorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Canvas.createdAt, ascending: false)],
        animation: .default)
    private var canvases: FetchedResults<Canvas>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(canvases) { canvas in
                    NavigationLink(destination: CanvasEditorView(canvas: canvas)) {
                        Text("Canvas created at \(canvas.createdAt!, formatter: itemFormatter)")
                    }
                }
                .onDelete(perform: deleteCanvases)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addCanvas) {
                        Label("Add Canvas", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Canvases")
            Text("Select a canvas")
        }
    }
    
    private func addCanvas() {
        withAnimation {
            let newCanvas = Canvas(context: viewContext)
            newCanvas.id = UUID()
            newCanvas.createdAt = Date()
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteCanvases(offsets: IndexSet) {
        withAnimation {
            offsets.map { canvases[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()
