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
    
    @Option(name: .shortAndLong, help: "Sets the build number for the project")
    var buildNumber: Int?
    
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
    var macExportPath: String { "\(directory)/exports/macos" }
    var defaultProjectName: String { "NewProject" }
    var archs: [String] { ["arm64-apple-macosx"] }
    var mode: String = "debug"
    
    mutating
    func perform(action: ActionType, godotFullPath path: String) throws {
        if let buildNumber {
            try setBuildNumber(buildNumber)
        }
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
        case .export:
            try exportProject(platform: platform)
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
    private func setBuildNumber(_ build: Int) throws {
        print("Setting build number to \(build)")
        let exportConfigPath = "\(directory)/export_presets.cfg"
        let exportConfig = try readFile(path: exportConfigPath)
        
        var configPresets: [ExportPreset] = []
        var buffer: [String] = []
        
        for (index, option) in exportConfig.enumerated() {
            if option.isPresetName || index == exportConfig.count - 1 {
                if !buffer.isEmpty {
                    configPresets.append(buffer)
                    buffer.removeAll()
                }
            }
            buffer.append(option)
        }
                
        for index in configPresets.indices {
            configPresets[index].setVersion("\(build)", short: false)
        }
        
        let result = configPresets.reduce([], +).joined(separator: "\n")
        try result.write(
            to: URL(fileURLWithPath: exportConfigPath),
            atomically: true,
            encoding: .utf8
        )
    }
    
    mutating
    private func exportProject(platform: PlatformType) throws {
        switch platform {
        case .mac:
            try buildGototMac()
            try exportGodotMac()
        case .ios:
            try buildGototIOS(isSimulator: false)
        case .iosSimulator:
            try buildGototIOS(isSimulator: true)
        }
    }
    
    private func exportGodotMac() throws {
        let exportName = "macOS (App Store)"
        try fileManager.createDirectoryIfNeeded(at: macExportPath)
        try export(exportName: exportName, path: macExportPath, fileType: "pkg")
    }
    
    mutating
    private func buildGodotDriver(platform: PlatformType) throws {
        switch platform {
        case .mac:
            try buildGototMac()
        case .ios:
            try buildGototIOS(isSimulator: false)
        case .iosSimulator:
            try buildGototIOS(isSimulator: true)
        }
    }
    
    mutating
    private func buildGototIOS(isSimulator: Bool) throws {
        projectName = try getProjectName()
        
        let destination = "generic/platform=\(isSimulator ? "iOS Simulator" : "iOS")"
        
        let archivePath = "\(driverPath)/xcodebuild.xcarchive"
        if fileManager.fileExists(atPath: archivePath) {
            try fileManager.removeItem(atPath: archivePath)
        }
        
//        let createWorkspace = "cd \(driverPath) && swift package generate-xcodeproj --output ./tmp"
//        try ShellCommand.stream(createWorkspace)
        
        // Build SwiftGodot driver as .xcarchive through xcbuild
        let command = "cd \(driverPath) && xcodebuild archive -scheme \(driverName) -configuration \(mode.capitalized) -archivePath ./xcodebuild -destination '\(destination)'"
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
        let exportName = isSimulator ? "iOS_Simulator" : "iOS"
        try fileManager.createDirectoryIfNeeded(at: iosExportPath)
        let projectPath = "\(directory)/project.godot"
        var project = try readFile(path: projectPath)
        
        // iOS Simulator crashes with rendering method set to 'mobile' or 'forward'
        // (on Apple Silicon Mac at least)
        // 'gl_compatibility' has an awful frameratte in Simulator but it works
        // I was unable to get Godot CLI '--rendering-method' argument working
        // So we write rendering method directly to .project file
        
        let renderMethod = isSimulator ? "gl_compatibility" : "mobile"
        var renderMethodIndex: Int?
        
        // TODO: Insert 'rendering_method.mobile' line when it's not present
        if let renderingIndex = project.firstIndex(where: { $0.contains("renderer/rendering_method.mobile") }) {
            // TODO: Handle cases when project does not have dedicated rendering_method.mobile entry
            renderMethodIndex = renderingIndex
            project[renderingIndex] = "renderer/rendering_method.mobile=\"\(renderMethod)\""
            if isSimulator {
                try overwriteFile(path: projectPath, contents: project)
                print("Changed rendering method to \(renderMethod)")
            }
        }
        
        try export(exportName: exportName, path: iosExportPath, fileType: "xcodeproj")
        
        // TODO: Rollback to the method that was used before sgint changed it
        if let index = renderMethodIndex, isSimulator {
            project[index] = "renderer/rendering_method.mobile=\"mobile\""
            try overwriteFile(path: projectPath, contents: project)
            print("Rendering method reset to mobile")
        }
    }
    
    private func export(
        exportName: String,
        path: String,
        fileType: String
    ) throws {
        let exportCommand = "cd \(directory) && \(try getGodotPath()) --headless --export-release \"\(exportName)\" \(path)/\(projectName?.corrected ?? "").\(fileType)"
        print(exportCommand)
        try ShellCommand.stream(exportCommand)
    }
    
    private func readFile(path: String) throws -> [String] {
        var arrayOfStrings: [String] = []
        
        if let data = fileManager.contents(atPath: path), let contents = String(data: data, encoding: .utf8) {
            arrayOfStrings = contents.components(separatedBy: "\n")
            return arrayOfStrings
        }
        return []
    }
    
    private func overwriteFile(path: String, contents: [String]) throws {
        try fileManager.removeItem(atPath: path)
        try contents.joined(separator: "\n").write(
            toFile: path,
            atomically: true,
            encoding: .utf8
        )
    }
    
    fileprivate func createExtensionFile() throws {
        // Create godot extension file
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
        case .ios, .iosSimulator:
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
    case export
}

enum PlatformType: String, Codable, ExpressibleByArgument {
    case ios
    case iosSimulator
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


typealias ExportPreset = Array<String>

extension ExportPreset {
    var presetName: String? {
        first(where: { $0.isPresetName })
    }
    
    var platform: String? {
        guard
            let platformOption = first(where: { $0.contains("platform=") }),
            let option = platformOption.split(separator: "=").last
        else {
            return nil
        }
        return option.replacingOccurrences(of: "\"", with: "").lowercased()
    }
    
    mutating
    func setVersion(_ version: String, short: Bool = false) {
        let versionKey = "application/\(short ? "short_version" : "version")="
        if let versionIndex = firstIndex(where: { $0.contains(versionKey) }) {
            self[versionIndex] = "\(versionKey)\"\(version)\""
        }
    }
}


extension String {
    var isPresetName: Bool {
        let regex = /\[preset.[1234567890]+\]/
        return !self.matches(of: regex).isEmpty
    }
}
