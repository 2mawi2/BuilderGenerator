//
//  ExpressionParserTests.swift
//  BuilderGeneratorTests
//
//  Created by Marius Wichtner on 07.11.21.
//

import Foundation
import XCTest
/*
 An expression represents a property or function where e.g.
 var property: String {
 var someProperty: String
 }
 signature: var property: String
 body: var someProperty: String
 */

struct Expression {
    var signature: String
    var body: String?
}

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension String.SubSequence {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}


func parseExpressions(content: String) -> [Expression] {
    let lines = content.split(separator: "\n")
    var expressions: [Expression] = []
    var currentExpression = Expression(signature: "", body: nil)
    var bracketCount = 0
    func inComplexExpression() -> Bool {
        return bracketCount > 0
    }
    func updateLineCounter(text: String) {
        bracketCount += text.trim().components(separatedBy: "{").count - 1
        bracketCount -= text.trim().components(separatedBy: "}").count - 1
    }
    for line in lines {
        let isSimpleExpression = !inComplexExpression() && !line.trim().isEmpty && !line.contains("{") && !line.contains("}")
        if isSimpleExpression {
            expressions.append(Expression(signature: String(line), body: nil))
            continue
        }
        let isStartOfComplexExpression = !inComplexExpression() && line.contains("{")
        if isStartOfComplexExpression {
            bracketCount += 1
            currentExpression.signature = String(line[..<line.firstIndex(of: "{")!]).trim()
            // TODO check for end of expression again
            continue
        }
        let isInComplexExpression = inComplexExpression() && !line.contains("}")
        if isInComplexExpression {
            if currentExpression.body == nil {
                currentExpression.body = ""
            }
            updateLineCounter(text: String(line))
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
        let isEndOfComplexExpression = line.contains("}") && bracketCount == 0
        if isEndOfComplexExpression {
            
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
class ExpressionParserTests: XCTestCase {
    
    func test_parseExpressions_parses_simple_expressions() {
        // arrange
        let content = """
var firstName: String?

var fullName: String {
    var fullName = PersonNameComponents()
    fullName.givenName = firstName
    fullName.middleName = middleName
    fullName.familyName = lastName
    return PersonNameFormatter.longNameFormatter.string(from: fullName)
}
"""
        // act
        let result = parseExpressions(content: content)
        // assert
        XCTAssertTrue(result.contains(where: {expression in
            expression.signature == "var firstName: String?" &&
                expression.body == nil
        }))
    }
    
    func test_parseExpressions_does_not_parse_empty_lines() {
        // arrange
        let content = """
var firstName: String?

 
var fullName: String {
    var fullName = PersonNameComponents()
    fullName.givenName = firstName
    fullName.middleName = middleName
    fullName.familyName = lastName
    return PersonNameFormatter.longNameFormatter.string(from: fullName)
}
"""
        // act
        let result = parseExpressions(content: content)
        // assert
        XCTAssertFalse(result.contains(where: { expression in
            expression.signature == "" || expression.signature == " "
        }))
    }
    
    func test_parseExpressions_parses_signature_of_complex_expression() {
        // arrange
        let content = """
var firstName: String?

var fullName: String {
    var fullName = PersonNameComponents()
    fullName.givenName = firstName
}
"""
        // act
        let result = parseExpressions(content: content)
        // assert
        XCTAssertTrue(result.contains(where: {expression in
            expression.signature == "var fullName: String"
        }))
    }
    
    func test_parseExpressions_parses_body_of_complex_expression() {
        // arrange
        let content = """
var fullName: String {
    var fullName = PersonNameComponents()
    fullName.givenName = firstName
    fullName.surename = firstName
}
"""
        // act
        let result = parseExpressions(content: content)
        // assert
        XCTAssertTrue(result.contains(where: {expression in
            expression.signature == "var fullName: String" &&
                expression.body!.contains("var fullName = PersonNameComponents()\nfullName.givenName = firstName\nfullName.surename = firstName\n")
        }))
    }
    
    func test_parseExpressions_parses_body_of_complex_expression_with_content_before_end_bracket() {
        // arrange
        let content = """
var fullName: String {
    var fullName = PersonNameComponents()
    fullName.surename = nil}
"""
        // act
        let result = parseExpressions(content: content)
        // assert
        XCTAssertTrue(result.contains(where: {expression in
            expression.signature == "var fullName: String" &&
                expression.body!.contains("var fullName = PersonNameComponents()\nfullName.surename = nil\n")
        }))
    }
    
    
    func test_parseExpressions_parses_body_of_nested_complex_expressions() {
        // arrange
        let content = """
func someFunc() -> String {
    var computedProperty: String {
        return "some"
    }
    var computedProperty: String {
        return "some"
    }
}
"""
        // act
        let result = parseExpressions(content: content)
        // assert
        XCTAssertEqual(
            result[0].body,
            "var computedProperty: String {\nreturn \"some\"\n}\nvar computedProperty: String {\nreturn \"some\"\n}\n")
    }
    
    func test_parseExpressions_parses_body_of_nested_inner_funcs() {
        // arrange
        let content = """
func someFunc() -> String {
    func nestedFunc() -> String {
        
    }
}
"""
        // act
        let result = parseExpressions(content: content)
        // assert
        XCTAssertEqual(
            result[0].body,
            "func nestedFunc() -> String {\n\n}\n")
            
            
    }
    
    
    
//    func test_parseExpressions_parses_body_of_complex_in_single_line() {
//        // arrange
//        let content = """
//var fullName: String { var fullName = PersonNameComponents() }
//"""
//        // act
//        let result = parseExpressions(content: content)
//        // assert
//        XCTAssertTrue(result.contains(where: {expression in
//            expression.signature == "var fullName: String" &&
//                expression.body!.contains("var fullName = PersonNameComponents()")
//        }))
//    }
}
