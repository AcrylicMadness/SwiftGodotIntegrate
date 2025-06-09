//
//  PlatformBuilder.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 09.06.2025.
//

import Foundation

protocol PlatformBuilder {
    
    var pathManager: PathManager { get }

    func build() throws
    func export() throws
    func run() throws
}

struct IOSBuilder: PlatformBuilder {
    
    let pathManager: PathManager
    
    func build() throws {
        
    }
    func export() throws { }
    func run() throws { }
    
}
