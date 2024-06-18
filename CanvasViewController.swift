//
//  CanvasViewController.swift
//  CanvasPDFExport
//
//  Created by Shahab on 2024-06-03.
//
import SwiftUI
import CoreData
import PDFKit

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
    var initialTouchPoint: CGPoint?
    var initialFrame: CGRect?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up canvas container view
        canvasContainerView = CanvasContainerView(frame: view.bounds)
        canvasContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasContainerView)
        
        if let canvas = canvas {
            canvasContainerView.canvasView.loadShapes(from: canvas)
        }
        
        // Add export button
        let exportButton = UIButton(type: .system)
        exportButton.setTitle("Export to PDF", for: .normal)
        exportButton.addTarget(self, action: #selector(exportToPDF), for: .touchUpInside)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.backgroundColor = .systemBlue
        exportButton.setTitleColor(.white, for: .normal)
        view.addSubview(exportButton)
        
        // Add delete button
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteSelectedShape), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.backgroundColor = .systemRed
        deleteButton.setTitleColor(.white, for: .normal)
        view.addSubview(deleteButton)
        
        // Add tap gesture recognizer for shape selection
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        canvasContainerView.canvasView.addGestureRecognizer(doubleTapGestureRecognizer)
        
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        canvasContainerView.canvasView.addGestureRecognizer(singleTapGestureRecognizer)

        
        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)


        
//        // Add pan gesture recognizer for shape movement
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        canvasContainerView.canvasView.addGestureRecognizer(panGestureRecognizer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(saveMovedShape(_:)), name: .shapeMoved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveDeletedShape(_:)), name: .shapeDeleted, object: nil)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            canvasContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            canvasContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            exportButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            exportButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            exportButton.widthAnchor.constraint(equalToConstant: 120),
            exportButton.heightAnchor.constraint(equalToConstant: 40),
            
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            deleteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            deleteButton.widthAnchor.constraint(equalToConstant: 120),
            deleteButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let touchPoint = gesture.location(in: canvasContainerView.canvasView)

        if gesture.numberOfTapsRequired == 2 {
            // Handle double tap: select shape
            _ = canvasContainerView.canvasView.selectShape(at: touchPoint)
        } else {
            // Handle single tap: add rectangle
            let shape = ShapeModel(id: UUID(), type: .rectangle, frame: CGRect(x: touchPoint.x - 50, y: touchPoint.y - 50, width: 100, height: 100), text: nil)
            canvasContainerView.canvasView.addShape(shape)
            saveShape(shape) // Save the newly added shape
        }
    }
    
    
//    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
//        switch gesture.state {
//        case .began:
//            initialTouchPoint = gesture.location(in: canvasContainerView.canvasView)
//            initialFrame = canvasContainerView.canvasView.selectedShapeLayer?.frame
//        case .changed:
//            guard let initialTouchPoint = initialTouchPoint, let initialFrame = initialFrame else { return }
//            let currentTouchPoint = gesture.location(in: canvasContainerView.canvasView)
//            let translation = CGPoint(x: currentTouchPoint.x - initialTouchPoint.x, y: currentTouchPoint.y - initialTouchPoint.y)
//            canvasContainerView.canvasView.moveSelectedShape(by: translation)
//        case .ended, .cancelled:
//            initialTouchPoint = nil
//            initialFrame = nil
//        default:
//            break
//        }
//    }
    
    @objc private func saveMovedShape(_ notification: Notification) {
        guard let shape = notification.userInfo?["shape"] as? ShapeModel else { return }
        saveShape(shape)
    }

    @objc private func saveDeletedShape(_ notification: Notification) {
        saveShapes()
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

    @objc private func deleteSelectedShape() {
        canvasContainerView.canvasView.deleteSelectedShape()
        saveShapes()
    }

    private func saveShape(_ shape: ShapeModel) {
        guard let context = canvas?.managedObjectContext else { return }
        
        let fetchRequest: NSFetchRequest<Shape> = Shape.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", shape.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            let shapeEntity = results.first ?? Shape(context: context)
            shapeEntity.id = shape.id
            shapeEntity.type = shape.type.rawValue
            shapeEntity.x = Double(shape.frame.origin.x)
            shapeEntity.y = Double(shape.frame.origin.y)
            shapeEntity.width = Double(shape.frame.size.width)
            shapeEntity.height = Double(shape.frame.size.height)
            shapeEntity.text = shape.text
            shapeEntity.canvas = canvas
            saveContext()
        } catch {
            print("Failed to fetch or create shape: \(error)")
        }
    }
    
    private func saveShapes() {
        guard let context = canvas?.managedObjectContext else { return }
        
        // Remove existing shapes
        if let existingShapes = canvas.shapes {
            for shape in existingShapes {
                context.delete(shape as! NSManagedObject)
            }
        }
        
        // Add updated shapes
        for shape in canvasContainerView.canvasView.shapes {
            let shapeEntity = Shape(context: context)
            shapeEntity.id = shape.id
            shapeEntity.type = shape.type.rawValue
            shapeEntity.x = Double(shape.frame.origin.x)
            shapeEntity.y = Double(shape.frame.origin.y)
            shapeEntity.width = Double(shape.frame.size.width)
            shapeEntity.height = Double(shape.frame.size.height)
            shapeEntity.text = shape.text
            shapeEntity.canvas = canvas
        }
        
        saveContext()
    }

    private func saveContext() {
        PersistenceController.shared.saveContext()
    }
}
