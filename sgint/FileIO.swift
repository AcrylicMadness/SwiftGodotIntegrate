//
//  FileIO.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 09.06.2025.
//

import Foundation

protocol FileIO {
    var fileManager: FileManager { get }
    func readFile(path: String) throws -> [String]
    func overwriteFile(path: String, contents: [String]) throws 
}

extension FileIO {
    
    var fileManager: FileManager { FileManager.default }
    
    func readFile(path: String) throws -> [String] {
        var arrayOfStrings: [String] = []
        
        if let data = fileManager.contents(atPath: path), let contents = String(data: data, encoding: .utf8) {
            arrayOfStrings = contents.components(separatedBy: "\n")
            return arrayOfStrings
        }
        return []
    }
    
    func overwriteFile(path: String, contents: [String]) throws {
        try fileManager.removeItem(atPath: path)
        try contents.joined(separator: "\n").write(
            toFile: path,
            atomically: true,
            encoding: .utf8
        )
    }
}
