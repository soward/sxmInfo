//
//  sxmWindow.swift
//  sxmInfo
//
//  Created by John Soward on 3/30/18.
//  Copyright © 2018 soward.net. All rights reserved.
//

import Foundation
import Cocoa

class sxmWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: .buffered, defer: false)
        self.isOpaque = false
        self.backgroundColor = NSColor.black
    }
}
