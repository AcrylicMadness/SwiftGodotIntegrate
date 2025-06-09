//
//  PathManager.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 09.06.2025.
//

import Foundation

struct PathManager {
    
    let directory: String
    
    private var fileManager: FileManager { FileManager.default }

    var defaultProjectName: String { "NewProject" }
    var driverName: String { "\(_projectName?.corrected ?? defaultProjectName)Driver" }
    var driverPath: String { directory + "/\(driverName)" }
    var binFolderPath: String { directory + "/bin" }
    var driverSourcesPath: String { driverPath + "/Sources/\(driverName)" }
    var xcodeArchivesPath: String { driverPath + "/xcodebuild" }
    var driverTestsPath: String { driverPath + "/Tests/\(driverName)Tests" }
    var iosExportPath: String { "\(directory)/exports/ios" }
    var macExportPath: String { "\(directory)/exports/macos" }
    
    private var _godotPath: String?
    var godotPath: String {
        get throws {
            if let _godotPath {
                if _godotPath.isValidGodotPath(appendingExecutable: false) {
                    return _godotPath.godotFullPath(appendingExecutable: false)
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
    }
    
    private var _projectName: String?
    private var projectName: String {
        get throws {
            if let _projectName {
                return _projectName.corrected
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
    
    init(
        projectName: String?,
        directory: String,
        godotPath: String?
    ) {
        self._projectName = projectName
        self.directory = directory
        self._godotPath = godotPath
    }
}
