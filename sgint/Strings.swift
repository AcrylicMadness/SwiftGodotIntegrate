//
//  Strings.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 10.12.2024.
//

import Foundation

enum Constants {
    static let godotSubpath: String = "/Contents/MacOS/Godot"
    static let godotExecutable: String = "Godot.app"
    
    static let searchPathsMasks: [FileManager.SearchPathDomainMask] = [
        .localDomainMask,
        .userDomainMask
    ]
    
    static func driverDlybs(name: String) -> [String] {[
        "libSwiftGodot",
        "lib\(name)"
    ]}
    
    static func driverFrameworks(name: String) -> [String] {[
        "SwiftGodot",
        name
    ]}
}

enum Templates { }
