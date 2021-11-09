//
//  SourceEditorCommand.swift
//  SourceEditorExtension
//
//  Created by Marius Wichtner on 06.11.21.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {

    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        defer { completionHandler(nil) }
        let file = generateBuilders(file: invocation.buffer.completeBuffer)
        invocation.buffer.completeBuffer.append(file)
    }
}
