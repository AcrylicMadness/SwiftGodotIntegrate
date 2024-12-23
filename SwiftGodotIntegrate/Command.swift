//
//  Command.swift
//  SwiftGodotIntegrate
//
//  Created by Acrylic M on 10.12.2024.
//

import Foundation

struct ShellCommand {
    @discardableResult
    static func stream(_ command: String) throws -> Int32 {
        let outputPipe = Pipe()
        let task = self.createProcess([command], outputPipe)
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            self.streamOutput(outputPipe, fileHandle) }
        
        try task.run()
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    @discardableResult
    static func streamSudo(_ command: String) throws -> Int32 {
        let testSudo = self.createSudoTestProcess()
        
        do {
            try testSudo.run()
            testSudo.waitUntilExit()
        } catch {
            return -1
        }
        
        if testSudo.terminationStatus == 0 {
            return try self.stream(command)
        }
        
        let pipe = Pipe()
        let sudo = self.createProcess(["sudo " + command], pipe)
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in self.streamOutput(pipe, fileHandle) }
        
        do {
            try sudo.run()
        } catch {
            return -1
        }
        
        if tcsetpgrp(STDIN_FILENO, sudo.processIdentifier) == -1 {
            return -1
        }
        
        sudo.waitUntilExit()
        
        return sudo.terminationStatus
    }
    
    @discardableResult
    static func runSudo(_ command: String) throws -> ShellResponse {
        let testSudo = self.createSudoTestProcess()
        
        do {
            try testSudo.run()
            testSudo.waitUntilExit()
        } catch {
            return ShellResponse(output: "", exitCode: -1)
        }
        
        if testSudo.terminationStatus == 0 {
            return try self.run(command)
        }
        
        let pipe = Pipe()
        var output = ""
        let sudo = self.createProcess(["sudo " + command], pipe)
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in self.saveOutput(pipe, fileHandle, &output) }
        
        do {
            try sudo.run()
        } catch {
            return ShellResponse(output: "", exitCode: -1)
        }
        
        if tcsetpgrp(STDIN_FILENO, sudo.processIdentifier) == -1 {
            return ShellResponse(output: "", exitCode: -1)
        }
        
        sudo.waitUntilExit()
        
        return ShellResponse(output: output, exitCode: sudo.terminationStatus)
    }
    
    @discardableResult
    static func run(_ commandToRun: String, printCommand: Bool = false, streamOutput: Bool = false, withSudo: Bool = false, path: String? = nil) throws -> ShellResponse {
        
        var command: String = ""
        
        if let path {
            command.append(path + " ")
        }
        
        command.append(commandToRun)
        
        let outputPipe = Pipe()
        let task = self.createProcess([command], outputPipe)
        var commandOutput = ""
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            self.saveOutput(outputPipe, fileHandle, &commandOutput)
        }
        try task.run()
        task.waitUntilExit()
        return ShellResponse(output: commandOutput, exitCode: task.terminationStatus)
    }
    
    private static func createProcess(_ arguments: [String], _ pipe: Pipe) -> Process {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c"] + arguments
        
        task.standardOutput = pipe
        task.standardError = pipe
        
        return task
    }
    
    private static func createSudoTestProcess() -> Process {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sudo -nv"]
        task.standardOutput = nil
        task.standardError = nil
        task.standardInput = nil
        
        return task
    }
    
    private static func saveOutput(_ pipe: Pipe, _ fileHandle: FileHandle, _ result: UnsafeMutablePointer<String>? = nil) -> Void {
        let data = fileHandle.availableData
        
        guard data.count > 0 else {
            pipe.fileHandleForReading.readabilityHandler = nil
            return
        }
        
        if let line = String(data: data, encoding: .utf8) {
            result?.pointee.append(line)
        }
    }
    
    private static func streamOutput(_ pipe: Pipe, _ fileHandle: FileHandle) -> Void {
        let data = fileHandle.availableData
        guard data.count > 0 else {
            pipe.fileHandleForReading.readabilityHandler = nil
            return
        }
        
        if let line = String(data: data, encoding: .utf8) {
            print(line, terminator: line.hasSuffix("\n") ? "" : "\n")
        }
    }
}

struct ShellResponse {
    var output: String
    var exitCode: Int32
    
    init(output: String = "", exitCode: Int32 = 0) {
        self.output = output
        self.exitCode = exitCode
    }
}
