//
//  CanvasView.swift
//  CanvasPDFExport
//
//  Created by Shahab on 2024-06-02.
//
import UIKit
import CoreData

enum ShapeType: String {
    case rectangle
    case circle
    case text
}

struct ShapeModel {
    var id: UUID
    var type: ShapeType
    var frame: CGRect
    var text: String?
}

class CanvasView: UIView {
    
    var shapes: [ShapeModel] = []
    var selectedShapeLayer: CAShapeLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBorder()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBorder()
    }
    
    private func setupBorder() {
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 2.0
    }
    
    func addShape(_ shape: ShapeModel) {
        shapes.append(shape)
        
        let shapeLayer: CAShapeLayer
        
        switch shape.type {
        case .rectangle:
            shapeLayer = CAShapeLayer()
            let path = UIBezierPath(rect: shape.frame)
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = UIColor.blue.cgColor
            
        case .circle:
            shapeLayer = CAShapeLayer()
            let path = UIBezierPath(ovalIn: shape.frame)
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = UIColor.red.cgColor
            
        case .text:
            let textLayer = CATextLayer()
            textLayer.frame = shape.frame
            textLayer.string = shape.text
            textLayer.foregroundColor = UIColor.black.cgColor
            textLayer.fontSize = 16
            textLayer.alignmentMode = .center
            textLayer.name = shape.id.uuidString
            layer.addSublayer(textLayer)
            return
        }
        
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 5
        shapeLayer.name = shape.id.uuidString
        shapeLayer.frame = shape.frame // Set the frame correctly
        
        layer.addSublayer(shapeLayer)
    }
    
    func loadShapes(from canvas: Canvas) {
        shapes = (canvas.shapes?.allObjects as? [Shape])?.compactMap { shape in
            let frame = CGRect(x: shape.x, y: shape.y, width: shape.width, height: shape.height)
            let text = shape.text
            return ShapeModel(id: shape.id!, type: ShapeType(rawValue: shape.type!)!, frame: frame, text: text)
        } ?? []
        
        for shape in shapes {
            addShape(shape)
        }
    }
    
    func selectShape(at point: CGPoint) -> CAShapeLayer? {
        let convertedPoint = layer.convert(point, from: self.layer)
        
        if let hitLayer = layer.hitTest(convertedPoint), let shapeLayer = findShapeLayer(in: hitLayer) {
            if selectedShapeLayer == shapeLayer {
                selectedShapeLayer?.borderWidth = 0 // Deselect if the same shape is tapped again
                selectedShapeLayer = nil
            } else {
                selectedShapeLayer?.borderWidth = 0 // Deselect previous shape
                selectedShapeLayer = shapeLayer
                selectedShapeLayer?.borderWidth = 2
                selectedShapeLayer?.borderColor = UIColor.red.cgColor // Highlight selected shape
            }
            return selectedShapeLayer
        } else {
            selectedShapeLayer?.borderWidth = 0 // Deselect previous shape
            selectedShapeLayer = nil
            return nil
        }
    }
    
    private func findShapeLayer(in layer: CALayer) -> CAShapeLayer? {
        if let shapeLayer = layer as? CAShapeLayer, shapes.contains(where: { $0.id.uuidString == shapeLayer.name }) {
            return shapeLayer
        } else if let sublayers = layer.sublayers {
            for sublayer in sublayers {
                if let foundLayer = findShapeLayer(in: sublayer) {
                    return foundLayer
                }
            }
        }
        return nil
    }
    
    func moveSelectedShape(by translation: CGPoint) {
        guard let selectedShapeLayer = selectedShapeLayer else { return }
        
        selectedShapeLayer.frame = selectedShapeLayer.frame.offsetBy(dx: translation.x, dy: translation.y)
        
        if let shapeIndex = shapes.firstIndex(where: { $0.id.uuidString == selectedShapeLayer.name }) {
            shapes[shapeIndex].frame = selectedShapeLayer.frame
            NotificationCenter.default.post(name: .shapeMoved, object: nil, userInfo: ["shape": shapes[shapeIndex]])
        }
    }
    
    func deleteSelectedShape() {
        guard let selectedShapeLayer = selectedShapeLayer else { return }
        selectedShapeLayer.removeFromSuperlayer()
        shapes.removeAll { $0.id.uuidString == selectedShapeLayer.name }
        NotificationCenter.default.post(name: .shapeDeleted, object: nil, userInfo: ["shape": selectedShapeLayer])
        self.selectedShapeLayer = nil
    }
}

extension Notification.Name {
    static let shapeMoved = Notification.Name("shapeMoved")
    static let shapeDeleted = Notification.Name("shapeDeleted")
}
