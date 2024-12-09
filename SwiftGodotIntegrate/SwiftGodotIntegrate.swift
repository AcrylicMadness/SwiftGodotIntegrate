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
    
    @Option(name: .shortAndLong, help: "Type of action to perform")
    var action: ActionType = .build
    
    @Option(name: .shortAndLong, help: "Directory to work in")
    var directory: String = FileManager.default.currentDirectoryPath
    
    @Option(name: .shortAndLong, help: "Path/To/Godot.app")
    var godotPath: String?
    
    @Flag(help: "Create project structure if none exists. Make sure to provide a name for the project")
    var createProject: Bool = false
    
    @Option(name: .shortAndLong, help: "Project name")
    var projectName: String?
    
    @Flag(help: "Verbose mode")
    var verbose: Bool = false
    
    var fileManager: FileManager { FileManager.default }
    
    var driverName: String { "\(projectName?.corrected ?? defaultProjectName)Driver" }
    var driverPath: String { directory + "/\(driverName)" }
    var binFolderPath: String { directory + "/bin" }
    var driverSourcesPath: String { driverPath + "/Sources/\(driverName)" }
    var driverTestsPath: String { driverPath + "/Tests/\(driverName)Tests" }
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
            try buildGodotDriver()
        case .run:
            try buildGodotDriver()
            try runGodot()
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
    private func buildGodotDriver() throws {
        
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
        
        // Create extension file
        let extensionPath = binFolderPath + "/\(driverName).gdextension"
        let extensionContents = Templates.extensionTemplate.withDriverName(name: driverName)
        
        try extensionContents.write(
            to: URL(fileURLWithPath: extensionPath),
            atomically: true,
            encoding: .utf8
        )
    }
    
    private func runGodot() throws {
        try ShellCommand.stream("cd \(directory) && \(try getGodotPath()) godot")
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

enum GodotIntegrateError: Error {
    case incorrectUserPath
    case godotNotFound
    case somethingWentWrong
    case templateNotFound
    case templateCorrupted
    case driverNotFound
    case multipleDriversFound
}
