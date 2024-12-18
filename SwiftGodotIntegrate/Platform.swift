//
//  Platform.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 18.12.2024.
//

import ArgumentParser
import Foundation

enum BuildPlatform: String, Decodable, ExpressibleByArgument {
    case iOS = "ios"
    case macOS = "mac"
    
    init?(argument: String) {
        self.init(rawValue: argument)
    }
}
