//
//  Utils.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 10.12.2024.
//

import Foundation

extension String {
    func godotFullPath(appendingExecutable: Bool = false) -> String {
        var path = self
        if appendingExecutable {
            path.append("/" + Constants.godotExecutable)
        }
        return path.appending(Constants.godotSubpath)
    }
    
    func isValidGodotPath(appendingExecutable: Bool) -> Bool {
        FileManager.default.fileExists(atPath: godotFullPath(appendingExecutable: appendingExecutable))
    }
    
    var corrected: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func withDriverName(name: String) -> String {
        replacingOccurrences(of: "{DRIVER_NAME}", with: name)
    }
}

extension FileManager {
    
    func createDirectoriesIfNeeded(at paths: [String]) throws {
        try paths.forEach { try createDirectoryIfNeeded(at: $0) }
    }
    
    func createDirectoryIfNeeded(at path: String) throws {
        if !fileExists(atPath: path) {
            try createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }
}

