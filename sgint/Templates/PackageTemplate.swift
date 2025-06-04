//
//  PackageTemplate.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 10.12.2024.
//

import Foundation

extension Templates {
    static let packageTemplate = """
// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "{DRIVER_NAME}",
    platforms: [.macOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "{DRIVER_NAME}",
            type: .dynamic,
            targets: ["{DRIVER_NAME}"]),
    ],
    dependencies: [
            .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main")
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "{DRIVER_NAME}",
            dependencies: [
                "SwiftGodot",
            ],
            swiftSettings: [.unsafeFlags(["-suppress-warnings"])]
        ),
        .testTarget(
            name: "{DRIVER_NAME}Tests",
            dependencies: ["{DRIVER_NAME}"]
        ),
    ]
)
"""
}
