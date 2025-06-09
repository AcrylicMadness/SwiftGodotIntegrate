//
//  SwiftGodotIntegrate+Package.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 10.12.2024.
//

import Foundation

extension SwiftGodotIntegrate {
    func createPackageStructure() throws {
        try fileManager.createDirectoriesIfNeeded(
            at: [
                binFolderPath,
                driverPath,
                driverSourcesPath,
                driverTestsPath
            ]
        )
        
        let packageFilePath = driverPath + "/Package.swift"
        let packageContents = Templates.packageTemplate.withDriverName(name: driverName)
        
        try packageContents.write(
            to: URL(fileURLWithPath: packageFilePath),
            atomically: true,
            encoding: .utf8
        )
        
        let driverFilePath = driverSourcesPath + "/\(driverName).swift"
        let driverContents = Templates.driverTemplate.withDriverName(name: driverName)
        
        try driverContents.write(
            to: URL(fileURLWithPath: driverFilePath),
            atomically: true,
            encoding: .utf8
        )
        
        let driverTestFilePath = driverTestsPath + "/\(driverName)Tests.swift"
        let driverTestContents = Templates.testsTemplate.withDriverName(name: driverName)
        
        try driverTestContents.write(
            to: URL(fileURLWithPath: driverTestFilePath),
            atomically: true,
            encoding: .utf8
        )
    }
}
