//
//  IOSBuilder.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 09.06.2025.
//

import Foundation

struct IOSBuilder: PlatformBuilder {
    
    let pathManager: PathManager
    let isSimulator: Bool
    
    let mode = "debug"
    
    func build() throws {
        let destination = "generic/platform=\(isSimulator ? "iOS Simulator" : "iOS")"
        
        let archivePath = "\(pathManager.driverPath)/xcodebuild.xcarchive"
        if fileManager.fileExists(atPath: archivePath) {
            try fileManager.removeItem(atPath: archivePath)
        }
        
        // Build SwiftGodot driver as .xcarchive through xcbuild
        let command = "cd \(pathManager.driverPath) && xcodebuild archive -scheme \(pathManager.driverName) -configuration \(mode.capitalized) -archivePath ./xcodebuild -destination '\(destination)'"
        try ShellCommand.stream(command)
        
        // Copy .framework files to /bin/ of Godot project
        for framework in Constants.driverFrameworks(name: pathManager.driverName) {
            let frameworkPath = "\(pathManager.driverPath)/xcodebuild.xcarchive/Products/usr/local/lib/\(framework).framework"
            let deistinationPath = "\(pathManager.binFolderPath)/\(framework).framework"
            
            let originUrl = URL(fileURLWithPath: frameworkPath)
            let destinationUrl = URL(fileURLWithPath: deistinationPath)
            
            if fileManager.fileExists(atPath: deistinationPath) {
                try fileManager.removeItem(atPath: deistinationPath)
            }
            
            try fileManager.copyItem(at: originUrl, to: destinationUrl)
        }
        
        try fileManager.removeItem(atPath: archivePath)
        try createExtensionFile()
    }
    
    func export() throws {
        // Build driver
        try build()
        
        let exportName = isSimulator ? "iOS_Simulator" : "iOS"
        try fileManager.createDirectoryIfNeeded(at: pathManager.iosExportPath)
        let projectPath = "\(pathManager.directory)/project.godot"
        var project = try readFile(path: projectPath)
        
        // iOS Simulator crashes with rendering method set to 'mobile' or 'forward'
        // (on Apple Silicon Mac at least)
        // 'gl_compatibility' has an awful frameratte in Simulator but it works
        // I was unable to get Godot CLI '--rendering-method' argument working
        // So we write rendering method directly to .project file
        let renderMethod = isSimulator ? "gl_compatibility" : "mobile"
        var renderMethodIndex: Int?
        
        // TODO: Insert 'rendering_method.mobile' line when it's not present
        if isSimulator, let renderingIndex = project.firstIndex(where: { $0.contains("renderer/rendering_method.mobile") }) {
            // TODO: Handle cases when project does not have dedicated rendering_method.mobile entry
            renderMethodIndex = renderingIndex
            project[renderingIndex] = "renderer/rendering_method.mobile=\"\(renderMethod)\""
            if isSimulator {
                try overwriteFile(path: projectPath, contents: project)
                print("Changed rendering method to \(renderMethod)")
            }
        }
        
        try exportGodot(exportName: exportName, path: pathManager.iosExportPath, fileType: "xcodeproj")
        
        // TODO: Rollback to the method that was used before sgint changed it
        if let index = renderMethodIndex, isSimulator {
            project[index] = "renderer/rendering_method.mobile=\"mobile\""
            try overwriteFile(path: projectPath, contents: project)
            print("Rendering method reset to mobile")
        }
    }
    
    func run() throws {
        try ShellCommand.stream("cd \(pathManager.directory) && open \(pathManager.iosExportPath)/\(pathManager.projectName).xcodeproj")
    }
}
