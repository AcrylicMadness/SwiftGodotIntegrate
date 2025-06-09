//
//  MacBuilder.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 09.06.2025.
//

import Foundation

struct MacBuilder: PlatformBuilder {
    let pathManager: PathManager
    let mode = "debug"
    
    private let archs: [String] = ["arm64-apple-macosx"]
    
    func build() throws {
        // Build SwiftGodot driver
        let command = "cd \(pathManager.driverPath) && swift build"
        try ShellCommand.stream(command)
        
        // Copy dlybs
        for dlybName in Constants.driverDlybs(name: pathManager.driverName) {
            for arch in archs {
                let dlybOriginPath = "\(pathManager.driverPath)/.build/\(arch)/\(mode)/\(dlybName).dylib"
                let dlybDestinationPath = "\(pathManager.binFolderPath)/\(dlybName).dylib"
                let originUrl = URL(fileURLWithPath: dlybOriginPath)
                let destinationUrl = URL(fileURLWithPath: dlybDestinationPath)
                
                if fileManager.fileExists(atPath: dlybDestinationPath) {
                    try fileManager.removeItem(atPath: dlybDestinationPath)
                }
                
                try fileManager.copyItem(at: originUrl, to: destinationUrl)
            }
        }
        
        try createExtensionFile()
    }
    
    func export() throws {
        try build()
        let exportName = "macOS (App Store)"
        try fileManager.createDirectoryIfNeeded(at: pathManager.macExportPath)
        try exportGodot(exportName: exportName, path: pathManager.macExportPath, fileType: "pkg")
    }
    
    func run() throws {
        try ShellCommand.stream("cd \(pathManager.directory) && \(pathManager.godotPath) godot")
    }
}
