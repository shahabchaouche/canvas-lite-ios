//
//  CanvasViewController.swift
//  CanvasPDFExport
//
//  Created by Shahab on 2024-06-03.
//

import SwiftUI
import PDFKit
import CoreData

struct CanvasEditorView: UIViewControllerRepresentable {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var canvas: Canvas

    func makeUIViewController(context: Context) -> CanvasViewController {
        let viewController = CanvasViewController()
        viewController.canvas = canvas
        return viewController
    }

    func updateUIViewController(_ uiViewController: CanvasViewController, context: Context) {
        // Update the view controller if needed.
    }

    class Coordinator: NSObject {
        var parent: CanvasEditorView

        init(parent: CanvasEditorView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

class CanvasViewController: UIViewController {
    var canvasContainerView: CanvasContainerView!
    var canvas: Canvas!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up canvas container view
        canvasContainerView = CanvasContainerView(frame: view.bounds)
        view.addSubview(canvasContainerView)
        
        if let canvas = canvas {
            canvasContainerView.canvasView.loadShapes(from: canvas)
        }
        
        // Add tap gesture recognizer for adding shapes
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        canvasContainerView.canvasView.addGestureRecognizer(tapGestureRecognizer)
        
        // Add export button
        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export to PDF", for: .normal)
        exportButton.addTarget(self, action: #selector(exportToPDF), for: .touchUpInside)
        exportButton.frame = CGRect(x: 20, y: self.view.bounds.height - 60, width: 120, height: 40)
        exportButton.backgroundColor = .systemBlue
        exportButton.setTitleColor(.white, for: .normal)
        self.view.addSubview(exportButton)
    }

    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        let locationInView = sender.location(in: canvasContainerView.canvasView)
        
        let shape = ShapeModel(
            id: UUID(),
            type: .rectangle, // Default to rectangle for simplicity
            frame: CGRect(x: locationInView.x - 50, y: locationInView.y - 50, width: 100, height: 100)
        )
        
        canvasContainerView.canvasView.addShape(shape)
        saveShape(shape)
    }

    @objc private func exportToPDF() {
        let pdfGenerator = PDFGenerator()
        guard let pdfURL = pdfGenerator.generatePDF(with: canvasContainerView.canvasView.shapes) else { return }
        
        // Display PDF
        let pdfView = PDFView(frame: self.view.bounds)
        pdfView.autoScales = true
        pdfView.document = PDFDocument(url: pdfURL)
        self.view.addSubview(pdfView)
    }

    private func saveShape(_ shape: ShapeModel) {
        guard let context = canvas?.managedObjectContext else { return }
        let entity = NSEntityDescription.entity(forEntityName: "Shape", in: context)!
        let shapeEntity = Shape(entity: entity, insertInto: context)
        shapeEntity.id = shape.id
        shapeEntity.type = shape.type.rawValue
        shapeEntity.x = Double(shape.frame.origin.x)
        shapeEntity.y = Double(shape.frame.origin.y)
        shapeEntity.width = Double(shape.frame.size.width)
        shapeEntity.height = Double(shape.frame.size.height)
        shapeEntity.text = shape.text
        shapeEntity.canvas = canvas
        canvas?.addToShapes(shapeEntity)
        saveContext()
    }

    private func saveContext() {
        PersistenceController.shared.saveContext()
    }
}
