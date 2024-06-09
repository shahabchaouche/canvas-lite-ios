//
//  CanvasContainerView.swift
//  CanvasPDFExport
//
//  Created by Shahab on 2024-06-09.
//

import UIKit

class CanvasContainerView: UIView, UIScrollViewDelegate {
    let scrollView = UIScrollView()
    let canvasView = CanvasView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupScrollView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupScrollView()
    }

    private func setupScrollView() {
        scrollView.frame = bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 3.0
        scrollView.backgroundColor = .white
        addSubview(scrollView)

        canvasView.frame = CGRect(x: 0, y: 0, width: 3000, height: 3000) // Large canvas size
        scrollView.addSubview(canvasView)
        scrollView.contentSize = canvasView.frame.size
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return canvasView
    }
}
