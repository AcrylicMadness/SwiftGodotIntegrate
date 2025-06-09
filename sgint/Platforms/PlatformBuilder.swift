//
//  PlatformBuilder.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 09.06.2025.
//

import Foundation

protocol PlatformBuilder: FileIO {
    
    var pathManager: PathManager { get }

    func build() throws
    func export() throws
    func run() throws
    func createExtensionFile() throws
    
    func exportGodot(
        exportName: String,
        path: String,
        fileType: String
    ) throws
}

extension PlatformBuilder {
    
    /// Runs Godot export command
    /// - Parameters:
    ///   - exportName: Godot export preset name
    ///   - path: Export path
    ///   - fileType: Export file extension
    func exportGodot(
        exportName: String,
        path: String,
        fileType: String
    ) throws {
        let project = try pathManager.projectName
        let godot = try pathManager.godotPath
        let exportCommand = "cd \(pathManager.directory) && \(godot) --headless --export-release \"\(exportName)\" \(path)/\(project).\(fileType)"
        print(exportCommand)
        try ShellCommand.stream(exportCommand)
    }
    
    /// Creates .gsextension file
    func createExtensionFile() throws {
        let extensionPath = pathManager.binFolderPath + "/\(pathManager.driverName).gdextension"
        let extensionContents = Templates.extensionTemplate.withDriverName(name: pathManager.driverName)
        try extensionContents.write(
            to: URL(fileURLWithPath: extensionPath),
            atomically: true,
            encoding: .utf8
        )
    }
}
