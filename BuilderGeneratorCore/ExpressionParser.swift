//
//  ExpressionParser.swift
//  BuilderGeneratorCore
//
//  Created by Marius Wichtner on 09.11.21.
//

import Foundation
import SwiftUI

class ExpressionParser {
    func parse(content: String) -> [Expression] {
        var expressions: [Expression] = []
        var lineIterator = content
            .split(separator: "\n")
            .map { String($0) }
            .map { stripComment(line: $0) }
            .makeIterator()
        while let current = lineIterator.next() {
            if current.trim().isEmpty {
                continue
            }
            let isSimple = !current.contains("{")
            if isSimple {
                expressions.append(Expression(signature: current, body: nil))
            } else {
                let complexExpression = ComplexExpressionParser().parse(&lineIterator, current)
                expressions.append(complexExpression)
            }
        }
        return expressions
    }
    
    private func stripComment(line: String) -> String {
        return line.contains("//")
            ? String(line[..<line.index(of: "//")!]).trim()
            : line
    }
}

func parseExpressions(content: String) -> [Expression] {
    return ExpressionParser().parse(content: content)
}

