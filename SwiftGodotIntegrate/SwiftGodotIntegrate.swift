//
//  SwiftGodotIntegrate.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 09.12.2024.
//

import ArgumentParser
import Foundation

@main
struct SwiftGodotIntegrate: AsyncParsableCommand {
    
    @Option(name: .shortAndLong, help: "Platform to build for")
    var platform: PlatformType = .mac
    
    @Option(name: .shortAndLong, help: "Type of action to perform")
    var action: ActionType = .build
    
    @Option(name: .shortAndLong, help: "Directory to work in")
    var directory: String = FileManager.default.currentDirectoryPath
    
    @Option(name: .shortAndLong, help: "Path/To/Godot.app")
    var godotPath: String?
    
    @Flag(help: "Create project structure if none exists. Make sure to provide a name for the project")
    var createProject: Bool = false
    
    @Option(name: .long, help: "Project name")
    var projectName: String?
    
    @Flag(help: "Verbose mode")
    var verbose: Bool = false
    
    var fileManager: FileManager { FileManager.default }
    
    var driverName: String { "\(projectName?.corrected ?? defaultProjectName)Driver" }
    var driverPath: String { directory + "/\(driverName)" }
    var binFolderPath: String { directory + "/bin" }
    var driverSourcesPath: String { driverPath + "/Sources/\(driverName)" }
    var xcodeArchivesPath: String { driverPath + "/xcodebuild" }
    var driverTestsPath: String { driverPath + "/Tests/\(driverName)Tests" }
    var iosExportPath: String { "\(directory)/exports/ios" }
    var defaultProjectName: String { "NewProject" }
    var archs: [String] { ["arm64-apple-macosx"] }
    var mode: String = "debug"
    
    mutating
    func perform(action: ActionType, godotFullPath path: String) throws {
        switch action {
        case .integrate:
            if createProject {
                try createProjectStructure()
                print("New project \(projectName?.corrected ?? defaultProjectName) created")
            }
            try createPackageStructure()
            print("SwiftGodot driver for \(projectName?.corrected ?? defaultProjectName) created at path: \(driverPath)")
        case .build:
            try buildGodotDriver(platform: platform)
        case .run:
            try buildGodotDriver(platform: platform)
            try runGodot(platform: platform)
        }
    }
    
    mutating func run() async throws {
        let path = try getGodotPath()
        let version = try ShellCommand.run("--version", path: path)
        print("Found Godot version \(version.output)")
        try perform(action: action, godotFullPath: path)
    }
    
    private func getGodotPath() throws -> String {
        if let godotPath {
            if godotPath.isValidGodotPath(appendingExecutable: false) {
                return godotPath.godotFullPath(appendingExecutable: false)
            } else {
                throw GodotIntegrateError.incorrectUserPath
            }
        }
        for mask in Constants.searchPathsMasks {
            let searchPaths = NSSearchPathForDirectoriesInDomains(.applicationDirectory, mask, true)
            for path in searchPaths where path.isValidGodotPath(appendingExecutable: true) {
                return path.godotFullPath(appendingExecutable: true)
            }
        }
        throw GodotIntegrateError.godotNotFound
    }
    
    private func createProjectStructure() throws {
        let url = URL(
            filePath: directory + "/project.godot"
        )
        try "".write(to: url, atomically: true, encoding: .utf8)
    }
    
    mutating
    private func buildGodotDriver(platform: PlatformType) throws {
        switch platform {
        case .mac:
            try buildGototMac()
        case .ios:
            try buildGototIOS()
        }
    }
    
    mutating
    private func buildGototIOS() throws {
        projectName = try getProjectName()
        
        let archivePath = "\(driverPath)/xcodebuild.xcarchive"
        if fileManager.fileExists(atPath: archivePath) {
            try fileManager.removeItem(atPath: archivePath)
        }
        
        // Build SwiftGodot driver as .xcarchive through xcbuild
        let command = "cd \(driverPath) && xcodebuild archive -scheme \(driverName) -configuration \(mode.capitalized) -archivePath ./xcodebuild -destination 'generic/platform=iOS'"
        try ShellCommand.stream(command)
        
        for framework in Constants.driverFrameworks(name: driverName) {
            let frameworkPath = "\(driverPath)/xcodebuild.xcarchive/Products/usr/local/lib/\(framework).framework"
            let deistinationPath = "\(binFolderPath)/\(framework).framework"
            
            let originUrl = URL(fileURLWithPath: frameworkPath)
            let destinationUrl = URL(fileURLWithPath: deistinationPath)
            
            if fileManager.fileExists(atPath: deistinationPath) {
                try fileManager.removeItem(atPath: deistinationPath)
            }
            
            try fileManager.copyItem(at: originUrl, to: destinationUrl)
        }
        
        try fileManager.removeItem(atPath: archivePath)
        try createExtensionFile()
        try fileManager.createDirectoryIfNeeded(at: iosExportPath)
        let exportCommand = "cd \(directory) && \(try getGodotPath()) --export-release iOS \(iosExportPath)/\(projectName?.corrected ?? "").xcodeproj"
        try ShellCommand.stream(exportCommand)
    }
    
    fileprivate func createExtensionFile() throws {
        // Create extension file
        let extensionPath = binFolderPath + "/\(driverName).gdextension"
        let extensionContents = Templates.extensionTemplate.withDriverName(name: driverName)
        
        try extensionContents.write(
            to: URL(fileURLWithPath: extensionPath),
            atomically: true,
            encoding: .utf8
        )
    }
    
    mutating
    private func buildGototMac() throws {
        projectName = try getProjectName()
        
        // Build SwiftGodot driver
        let command = "cd \(driverPath) && swift build"
        try ShellCommand.stream(command)
        
        // Copy dlybs
        for dlybName in Constants.driverDlybs(name: driverName) {
            for arch in archs {
                let dlybOriginPath = "\(driverPath)/.build/\(arch)/\(mode)/\(dlybName).dylib"
                let dlybDestinationPath = "\(binFolderPath)/\(dlybName).dylib"
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
    
    private func runGodot(platform: PlatformType) throws {
        switch platform {
        case .mac:
            try ShellCommand.stream("cd \(directory) && \(try getGodotPath()) godot")
        case .ios:
            try ShellCommand.stream("cd \(directory) && open \(iosExportPath)/\(projectName?.corrected ?? "").xcodeproj")
        }
    }
    
    private func getProjectName() throws -> String {
        if let projectName {
            return projectName.corrected
        }
        
        let items = try fileManager.contentsOfDirectory(atPath: directory)
        let projects = items.filter { $0.contains("Driver") }
        
        if projects.count > 1 {
            throw GodotIntegrateError.multipleDriversFound
        }
        
        guard let project = projects.first else {
            throw GodotIntegrateError.driverNotFound
        }
        
        return project.replacingOccurrences(of: "Driver", with: "")
    }
}

enum ActionType: String, Codable, ExpressibleByArgument {
    case integrate
    case build
    case run
}

enum PlatformType: String, Codable, ExpressibleByArgument {
    case ios
    case mac
}

enum GodotIntegrateError: Error {
    case incorrectUserPath
    case godotNotFound
    case somethingWentWrong
    case templateNotFound
    case templateCorrupted
    case driverNotFound
    case multipleDriversFound
    case unknownPlatform
}
