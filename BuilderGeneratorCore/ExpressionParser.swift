//
//  ExpressionParser.swift
//  BuilderGeneratorCore
//
//  Created by Marius Wichtner on 09.11.21.
//

import Foundation

func parseExpressions(content: String) -> [Expression] {
    var expressions: [Expression] = []
    var currentExpression = Expression(signature: "", body: nil)
    var bracketCount = 0
    for line in content.split(separator: "\n") {
        if isSimpleExpression(bracketCount, line) {
            expressions.append(Expression(signature: String(line), body: nil))
            continue
        }
        if isStartOfComplexExpression(bracketCount, line) {
            bracketCount += 1
            currentExpression.signature = String(line[..<line.firstIndex(of: "{")!]).trim()
            // TODO check for end of expression again
            continue
        }
        if isInComplexExpression(bracketCount, line) {
            if currentExpression.body == nil {
                currentExpression.body = ""
            }
            bracketCount = calculateNewBracketCount(bracketCount, String(line))
            currentExpression.body?.append(String(line.trim()))
            currentExpression.body?.append("\n")
        }
        if line.contains("}") {
            let occurencies = line.trim().components(separatedBy: "}").count - 1
            bracketCount -= occurencies
            let remainder = String(line[..<line.firstIndex(of: "}")!]).trim()
            if remainder.isEmpty {
                for _ in 0..<occurencies {
                   currentExpression.body?.append("}\n")
               }
            }
        }
        if isEndOfComplexExpression(line, bracketCount) {
            let remainder = String(line[..<line.firstIndex(of: "}")!]).trim()
            if !remainder.isEmpty {
                currentExpression.body?.append(remainder)
                currentExpression.body?.append("\n")
            }
            
            if currentExpression.body?.hasSuffix("}\n") ?? false {
                currentExpression.body?.removeLast(2)
            }

            expressions.append(currentExpression)
            currentExpression = Expression(signature: "", body: nil)
        }

    }
    return expressions
}


private func calculateNewBracketCount(_ bracketCount: Int,_ text: String) -> Int {
    var newBracketCount = bracketCount
    newBracketCount += text.trim().components(separatedBy: "{").count - 1
    newBracketCount -= text.trim().components(separatedBy: "}").count - 1
    return newBracketCount
}

private func inComplexExpression(_ bracketCount: Int) -> Bool {
    return bracketCount > 0
}

private func isSimpleExpression(_ bracketCount: Int, _ line: String.SubSequence) -> Bool {
    return !inComplexExpression(bracketCount) && !line.trim().isEmpty && !line.contains("{") && !line.contains("}")
}

private func isStartOfComplexExpression(_ bracketCount: Int, _ line: String.SubSequence) -> Bool {
    return !inComplexExpression(bracketCount) && line.contains("{")
}

private func isInComplexExpression(_ bracketCount: Int, _ line: String.SubSequence) -> Bool {
    return inComplexExpression(bracketCount) && !line.contains("}")
}

private func isEndOfComplexExpression(_ line: String.SubSequence, _ bracketCount: Int) -> Bool {
    return line.contains("}") && bracketCount == 0
}

