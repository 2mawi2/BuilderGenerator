//
//  ExpressionParserTests.swift
//  BuilderGeneratorCoreTests
//
//  Created by Marius Wichtner on 09.11.21.
//

import XCTest
import Foundation

@testable import BuilderGeneratorCore

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
}
