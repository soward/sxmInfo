//
//  coloredTableViewRow.swift
//  sxmInfo
//
//  Created by John Soward on 3/27/18.
//  Copyright © 2018 soward.net. All rights reserved.
//

import Foundation
import Cocoa

class customTableViewRow: NSTableRowView {
    var thisRow = -1
    override func draw(_ dirtyRect: NSRect) {
        if ( (thisRow % 2) == 1 ) {
            backgroundColor=NSColor.black
        } else {
            backgroundColor=NSColor.darkGray
        }
        super.draw(dirtyRect)
    }
    
    override func drawSelection(in dirtyRect: NSRect) {
        backgroundColor = NSColor.black
        NSColor.init(red: 0.3, green: 0.0, blue: 0.01, alpha: 1.0).setFill()
        __NSRectFill(dirtyRect)
    }
}
