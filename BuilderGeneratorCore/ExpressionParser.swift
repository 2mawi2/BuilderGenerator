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
            
            let remainingLine = String(line[line.firstIndex(of: "{")!...]).trim().remove("{")
            if remainingLine.contains("}") {
                let occurencies = remainingLine.trim().components(separatedBy: "}").count - 1
                bracketCount -= occurencies
                if isEndOfComplexExpression(String.SubSequence(remainingLine), bracketCount) {
                    let remainder = String(remainingLine[..<remainingLine.firstIndex(of: "}")!]).trim()
                    if !remainder.isEmpty {
                        currentExpression.appendOrSetBody(remainder)
                    }
                    expressions.append(currentExpression)
                    currentExpression = Expression(signature: "", body: nil)
                }
            }
            
            continue
        }
        if isInComplexExpression(bracketCount, line) {
            bracketCount = calculateNewBracketCount(bracketCount, String(line))
            currentExpression.appendOrSetBody(String(line.trim()))
            currentExpression.appendOrSetBody("\n")
        }
        if line.contains("}") {
            let occurencies = line.trim().components(separatedBy: "}").count - 1
            bracketCount -= occurencies
            let remainder = String(line[..<line.firstIndex(of: "}")!]).trim()
            if remainder.isEmpty {
                for _ in 0..<occurencies {
                    currentExpression.appendOrSetBody("}\n")
               }
            }
        }
        if isEndOfComplexExpression(line, bracketCount) {
            let remainder = String(line[..<line.firstIndex(of: "}")!]).trim()
            if !remainder.isEmpty {
                currentExpression.appendOrSetBody(remainder)
                currentExpression.appendOrSetBody("\n")
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

