//
//  GeneratorTests.swift
//  SourceEditorExtension
//
//  Created by Marius Wichtner on 09.11.21.
//

import Foundation

import XCTest
import Foundation



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
        let resultStruct = StructParser().parseStructs(content: content)
        // assert
        XCTAssertTrue(resultStruct.isEmpty)
    }
    
    func test_parse_struct_should_contain_name_of_struct() throws {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = StructParser().parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.name, "MyProfile")
    }
    
    func test_parse_struct_parses_all_fields() throws {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = StructParser().parseStructs(content: content)[0]
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
        let resultStruct = StructParser().parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.fields.count, 2)
    }
    
    func test_parse_struct_parses_correct_field_names() {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = StructParser().parseStructs(content: content)[0]
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
        let resultStruct = StructParser().parseStructs(content: content)[0]
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
        let resultStruct = StructParser().parseStructs(content: content)[0]
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
        let resultStruct = StructParser().parseStructs(content: content)[0]
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
        let resultStruct = StructParser().parseStructs(content: content)[0]
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
        let resultStruct = StructParser().parseStructs(content: content)[0]
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
        let resultStruct = StructParser().parseStructs(content: content)[0]
        // assert
        XCTAssertEqual(resultStruct.name, "MyProfile")
    }
    
}


class BuilderGeneratorTests: XCTestCase {
    func test_generate_builder_for_struct() {
        // arrange
        let content = """
        import Foundation
        struct MyProfile: Profile {
            var name: String
            let age: Int
        }
        """
        // act
        let result = BuilderGenerator().generateBuilders(file: content)
        // assert
        XCTAssertEqual(result.contains("struct MyProfileBuilder"), true)
    }
    
    func test_generate_builder_considers_all_fields_with_correct_default_values() {
        // arrange
        let content = """
        import Foundation
        struct MyProfile: Profile {
            var name: String
            let age: Int
        }
        """
        // act
        let result = BuilderGenerator().generateBuilders(file: content)
        // assert
        XCTAssertEqual(result.contains("var name: String = \"\""), true)
        XCTAssertEqual(result.contains("var age: Int = 0"), true)
    }
    
    func test_generate_builder_considers_all_fields_with_correct_default_values_all_possible_types() {
        // arrange
        let content = """
        import Foundation
        struct MyProfile: Profile {
            var name: String
            let age: Int
            let height: Float
            let height2: Double
            let isActive: Bool
            let friends: [String]
            let nullableFriends: [String]?
            var nullableName: String?
            var unknown: UnknownStructOrEnum
        }
        """
        // act
        let result = BuilderGenerator().generateBuilders(file: content)
        // assert
        XCTAssertEqual(result.contains("var name: String = \"\""), true)
        XCTAssertEqual(result.contains("var age: Int = 0"), true)
        XCTAssertEqual(result.contains("var height: Float = 0.0"), true)
        XCTAssertEqual(result.contains("var height2: Double = 0.0"), true)
        XCTAssertEqual(result.contains("var isActive: Bool = false"), true)
        XCTAssertEqual(result.contains("var friends: [String] = []"), true)
        XCTAssertEqual(result.contains("var nullableFriends: [String]?"), true)
        XCTAssertEqual(result.contains("var nullableName: String?"), true)
        XCTAssertEqual(result.contains("var unknown: UnknownStructOrEnum = UnknownStructOrEnumBuilder().build()"), true)
    }
    
    func test_generate_builder_can_handle_properties_of_sub_scope() {
        // arrange
        let content = """
            struct PersonalData: Codable, Equatable {
                
                var firstName: String?
            
                var fullName: String {
                    var fullName = PersonNameComponents()
                    fullName.givenName = firstName
                    fullName.middleName = middleName
                    fullName.familyName = lastName
                    return PersonNameFormatter.longNameFormatter.string(from: fullName)
                }
            }
            """
        // act
        let result = BuilderGenerator().generateBuilders(file: content)
        // assert
        XCTAssertEqual(result.contains("var firstName: String?"), true)
        XCTAssertFalse(result.contains("fullName"))
    }
    
    func test_generate_builder_can_handle_generics() {
        // arrange
        let content = """
        struct ContentPage<T:Codable>: Codable {
            var items: [T] = []
            var paging: ContentPaging?
        
            enum CodingKeys: String, CodingKey {
                case items = "data"
                case paging = "paging"
            }
        }
        """
        // act
        let result = BuilderGenerator().generateBuilders(file: content)
        // assert
        XCTAssertTrue(result.contains("var items: [T] = []"))
        XCTAssertTrue(result.contains("var paging: ContentPaging?"))
        XCTAssertTrue(result.contains("struct ContentPageBuilder<T:Codable> {"))
    }
    
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
}
