//
//  CanvasPDFExport.swift
//  CanvasPDFExport
//
//  Created by Shahab on 2024-06-03.
//
import SwiftUI

@main
struct CanvasPDFExport: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CanvasSelectorView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
