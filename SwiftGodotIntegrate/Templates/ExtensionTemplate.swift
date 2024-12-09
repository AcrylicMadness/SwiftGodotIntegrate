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


[dependencies]
macos.debug = {"res://bin/libSwiftGodot.dylib" : ""}

"""
}
