//
//  PDFGenerator.swift
//  CanvasPDFExport
//
//  Created by Shahab on 2024-06-02.
//
import PDFKit

class PDFGenerator {
    
    func generatePDF(with shapes: [ShapeModel]) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "PDF Generator",
            kCGPDFContextAuthor: "Your Name",
            kCGPDFContextTitle: "Sample PDF"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let pdfData = renderer.pdfData { (context) in
            context.beginPage()
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24.0),
                .foregroundColor: UIColor.black
            ]
            let title = "Hello, PDF!"
            title.draw(at: CGPoint(x: 72, y: 72), withAttributes: titleAttributes)
            
            for shape in shapes {
                switch shape.type {
                case .rectangle:
                    context.cgContext.setFillColor(UIColor.blue.cgColor)
                    context.cgContext.setStrokeColor(UIColor.black.cgColor)
                    context.cgContext.setLineWidth(5)
                    context.cgContext.addRect(shape.frame)
                    context.cgContext.drawPath(using: .fillStroke)
                case .circle:
                    context.cgContext.setFillColor(UIColor.red.cgColor)
                    context.cgContext.setStrokeColor(UIColor.black.cgColor)
                    context.cgContext.setLineWidth(5)
                    context.cgContext.addEllipse(in: shape.frame)
                    context.cgContext.drawPath(using: .fillStroke)
                case .text:
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 16.0),
                        .foregroundColor: UIColor.black
                    ]
                    shape.text?.draw(in: shape.frame, withAttributes: attributes)
                }
            }
        }
        
        let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = documentDirectories.first!
        let outputURL = documentDirectory.appendingPathComponent("SamplePDF.pdf")
        
        do {
            try pdfData.write(to: outputURL)
            return outputURL
        } catch {
            print("Could not create PDF file: \(error)")
            return nil
        }
    }
}
