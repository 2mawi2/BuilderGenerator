//
//  ExpressionParser.swift
//  BuilderGeneratorCore
//
//  Created by Marius Wichtner on 09.11.21.
//

import Foundation
import SwiftUI

typealias Iterator = IndexingIterator<[String]>

class ComplexExpressionParser {
    
    func parse(_ iterator: inout Iterator, _ currentLine: String) -> Expression {
        return newBracketCount(0, currentLine) == 0
            ? parseSingleLineExpression(currentLine)
            : parseMultilineExpression(currentLine, &iterator)
    }
    
    private func signature(of currentLine: String) -> String {
        return String(currentLine[..<currentLine.firstIndex(of: "{")!]).trim()
    }
    
    private func remainder(of currentLine: String) -> String {
        return String(currentLine[currentLine.firstIndex(of: "{")!...]).trim()
    }
    
    private func parseSingleLineExpression(_ currentLine: String) -> Expression {
        let body = remainder(of: currentLine).remove("{").remove("}").trim()
        return Expression(signature: signature(of: currentLine), body: body)
    }
    
    private func parseMultilineExpression(_ currentLine: String, _ iterator: inout Iterator) -> Expression {
        var bracketCount = newBracketCount(0, currentLine)
        var body = remainder(of: currentLine).remove("{")
        while let nextLine = iterator.next(), bracketCount > 0 {
            bracketCount = newBracketCount(bracketCount, nextLine)
            var trimmedLine = nextLine.trim()
            if bracketCount == 0 && trimmedLine.hasSuffix("}") {
                trimmedLine.removeLast()
            }
            if !trimmedLine.isEmpty {
                body.append(contentsOf: trimmedLine + "\n")
            }
        }
        return Expression(signature: signature(of: currentLine), body: body)
    }
    
    private func newBracketCount(_ bracketCount: Int, _ text: String) -> Int {
        return bracketCount + text.count("{") - text.count("}")
    }
}

class ExpressionParser {
    func parse(content: String) -> [Expression] {
        var expressions: [Expression] = []
        var lineIterator = content.split(separator: "\n").map { String($0) }.makeIterator()
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
}

func parseExpressions(content: String) -> [Expression] {
    return ExpressionParser().parse(content: content)
}

