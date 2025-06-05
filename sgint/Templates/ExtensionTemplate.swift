//
//  ExtensionTemplate.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 10.12.2024.
//

import Foundation

extension Templates {
    static let extensionTemplate = """
[configuration]
entry_symbol = "swift_entry_point"
compatibility_minimum = 4.2


[libraries]
macos.debug = "res://bin/lib{DRIVER_NAME}.dylib"
macos.release = "res://bin/lib{DRIVER_NAME}.dylib"
ios.debug = "res://bin/lib{DRIVER_NAME}.framework"
ios.release = "res://bin/{DRIVER_NAME}.framework"


[dependencies]
macos.debug = {"res://bin/libSwiftGodot.dylib" : ""}
macos.release = "res://bin/libSwiftGodot}.dylib"
ios.debug = {"res://bin/SwiftGodot.framework" : ""}
ios.release = {"res://bin/SwiftGodot.framework" : ""}

"""
}
