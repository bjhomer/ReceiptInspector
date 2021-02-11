//
//  DragTargetView.swift
//  ReceiptInspector
//
//  Created by BJ Homer on 7/5/17.
//  Copyright © 2017 BJ Homer. All rights reserved.
//

import Cocoa

@objc protocol DragTargetViewDelegate {
    func dragTargetViewChangedURL(_ dragTargetView: DragTargetView)
}

class DragTargetView: NSView {

    fileprivate var isDraggingInside: Bool = false {
        didSet { needsDisplay = true }
    }
    fileprivate var draggedImage: NSImage? = nil {
        didSet { needsDisplay = true }
    }
    
    var url: URL? = nil {
        didSet{ delegate?.dragTargetViewChangedURL(self) }
    }
    weak var delegate: DragTargetViewDelegate? = nil
    
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        guard newWindow != nil else { return }
        
        registerForDraggedTypes([.init("public.file-url")])
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let border = NSBezierPath(rect: self.bounds)
        
        NSColor.lightGray.setFill()
        border.fill()
        
        if isDraggingInside {
            let ringColor = NSColor.blue
            ringColor.setStroke()
            border.lineWidth = 5
            
            border.stroke()
        }
        
        if let image = self.draggedImage {
            let insetBounds = self.bounds.insetBy(dx: 6, dy: 6)
            image.draw(in: insetBounds)
        }
    }
    
}


extension DragTargetView {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.isDraggingInside = true
        return .generic
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.isDraggingInside = false
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDraggingInside = false
        
        let pasteboard = sender.draggingPasteboard
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]),
            let draggedURL = urls.first as? NSURL
            else { return false }
        
        draggedImage = NSWorkspace.shared.icon(forFile: draggedURL.path!)
        
        
        self.url = draggedURL as URL
        return true
    }
}
