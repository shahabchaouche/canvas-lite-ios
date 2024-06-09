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
        
        switch shape.type {
        case .rectangle:
            let shapeLayer = CAShapeLayer()
            let path = UIBezierPath(rect: shape.frame)
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = UIColor.blue.cgColor
            shapeLayer.strokeColor = UIColor.black.cgColor
            shapeLayer.lineWidth = 5
            layer.addSublayer(shapeLayer)
            
        case .circle:
            let shapeLayer = CAShapeLayer()
            let path = UIBezierPath(ovalIn: shape.frame)
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = UIColor.red.cgColor
            shapeLayer.strokeColor = UIColor.black.cgColor
            shapeLayer.lineWidth = 5
            layer.addSublayer(shapeLayer)
            
        case .text:
            let textLayer = CATextLayer()
            textLayer.frame = shape.frame
            textLayer.string = shape.text
            textLayer.foregroundColor = UIColor.black.cgColor
            textLayer.fontSize = 16
            textLayer.alignmentMode = .center
            layer.addSublayer(textLayer)
        }
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
}
