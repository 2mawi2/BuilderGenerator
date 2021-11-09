//
//  StructParserTests.swift
//  BuilderGeneratorCoreTests
//
//  Created by Marius Wichtner on 09.11.21.
//

import XCTest
import Foundation

@testable import BuilderGeneratorCore

class StructParserTests: XCTestCase {
    
    let singleStruct = """
struct MyProfile: Profile {
    var name: String
    let age: Int
}
"""
    
    
    func test_parse_struct_should_return_nil_if_file_contains_a_class() throws {
        // arrange
        let content = """
        class MyProfile: Profile {
            var name: String
            var age: Int
        }
        """
        // act
        let resultStruct = parseStructs(content: content)
        // assert
        XCTAssertTrue(resultStruct.isEmpty)
    }
    
    func test_parse_struct_should_contain_name_of_struct() throws {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.name, "MyProfile")
    }
    
    func test_parse_struct_parses_all_fields() throws {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.fields.count, 2)
    }
    
    func test_parse_struct_parses_all_fields_with_spacing() throws {
        // arrange
        let content = """
        struct MyProfile: Equatable {
            var  isActive :   Bool
            var   city: String ?
        }
"""
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.fields.count, 2)
    }
    
    func test_parse_struct_parses_correct_field_names() {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.fields[0].name, "name")
        XCTAssertEqual(resultStruct.fields[1].name, "age")
    }
    
    func test_parse_struct_parses_correct_types() {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.fields[0].type, "String")
        XCTAssertEqual(resultStruct.fields[1].type, "Int")
    }
    
    func test_parse_struct_parses_correct_optional_types() {
        // arrange
        let content = """
        struct MyProfile: Equatable {
            var  isActive :   Bool
            let   city: String ?
        }
        """
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.fields[0].optional, false)
        XCTAssertEqual(resultStruct.fields[1].optional, true)
    }
    
    func test_parse_struct_ignores_computed_properties() {
        // arrange
        let content = """
        struct MyProfile: Equatable {
            var  isActive :   Bool
            let   city: String
            var   name: String {
                return "John"
            }
        }
        """
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.fields.count, 2)
    }
    
    func test_parse_struct_parses_correct_names_with_default_values() {
        // arrange
        let content = """
        struct MyProfile: Profile {
            var name: String = "default"
            let age: Int = 1
        }
        """
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.fields[0].name, "name")
        XCTAssertEqual(resultStruct.fields[1].name, "age")
    }
    
    func test_parse_struct_ignores_coding_keys() {
        // arrange
        let content = """
        struct MyProfile: Profile {
        var name: String = "default"
        let age: Int = 1
        enum CodingKeys: String, CodingKey {
            case name
            case age
        }
        }
        """
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.fields.count, 2)
    }
    
    func test_parse_should_ignore_imports_when_parsing_name() {
        // arrange
        let content = """
        import Foundation
        struct MyProfile: Profile {
            var name: String = "default"
            let age: Int = 1
        }
        """
        // act
        let resultStruct = parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.name, "MyProfile")
    }
    
}
