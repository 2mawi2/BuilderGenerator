import XCTest

/*
 A script that reads a swift file and generates code for a builder
 
 Example:
 input:
 struct MyProfile: Equatable {
 var isActive: Bool
 var city: String?
 }
 output:
 struct MyProfileBuilder {
 var isActive: Bool = false
 var city: String?
 
 func build() -> MyProfile {
 MyProfile(
 isActive: isActive,
 city: city
 )
 }
 }
 */
import Foundation


struct Field: Codable {
    let name: String
    let type: String
    let optional: Bool
}

struct Struct: Codable {
    let name: String
    let fields: [Field]
    var generics: String = ""
}


struct StructParser {
    func parseStruct(content: String) -> Struct? {
        if numberOfStructs(content: content) != 1 { return nil }
        let expressions = parseExpressions(content: content)
        guard let str = expressions.first(where: {expression in expression.signature.contains("struct")}) else {
            return nil
        }
        let name = parseStructName(str)
        guard let body = str.body else {
            return nil
        }
        let fields = parseFields(body: body)
        let generics = parseGenerics(str: str)
        return Struct(name: name, fields: fields, generics: generics)
    }

    private func parseGenerics(str: Expression) -> String {
        let signature = str.signature
        if signature.contains("<") && signature.contains(">") {
            let startIndex = signature.index(signature.startIndex, offsetBy: signature.range(of: "<")!.upperBound.encodedOffset)
            let endIndex = signature.index(signature.startIndex, offsetBy: signature.range(of: ">")!.lowerBound.encodedOffset)
            let range = startIndex..<endIndex
            let generics = signature[range]
            return "<\(String(generics))>"
        } else {
            return ""
        }
    }

    private func parseStructName(_ str: Expression) -> String {
        let signatureWithoutStruct = str.signature.replacingOccurrences(of: "struct", with: "")
        let hasGenerics = signatureWithoutStruct.contains("<")
        if hasGenerics {
            return signatureWithoutStruct
                .split(separator: "<")[0]
                .trimmingCharacters(in: .whitespaces)
               
        } else {
            return signatureWithoutStruct
                .split(separator: ":")[0]
                .trimmingCharacters(in: .whitespaces)
        }
        
    }
    
    private func numberOfStructs(content: String) -> Int {
        return content.components(separatedBy: "struct").count - 1
    }
    
    private func parseFields(body: String) -> [Field] {
        var fields = [Field]()
        var bodyWithoutEnclosingBrackets = body
        let expressions = parseExpressions(content: bodyWithoutEnclosingBrackets)
        
        for expression in expressions {
            if expression.body == nil {
                let signature = expression.signature
                if signature.contains("var") || signature.contains("let") {
                    let field = parseField(line: signature)
                    fields.append(field)
                }
            }
        }
        return fields
    }
    
    private func parseField(line: String) -> Field {
        let lineWithoutVarOrLet = line
            .replacingOccurrences(of: "var", with: "")
            .replacingOccurrences(of: "let", with: "")
        let components = lineWithoutVarOrLet.components(separatedBy: ":")
        let name = components[0].trimmingCharacters(in: .whitespaces)
        var type = components[1].trimmingCharacters(in: .whitespaces)
        let optional = type.contains("?")
        if optional {
            type = type.replacingOccurrences(of: "?", with: "")
        }
        if type.contains("=") {
            let indexOfEquals = type.firstIndex(of: "=")!
            type = String(type[..<indexOfEquals])
            type = type.trimmingCharacters(in: .whitespaces)
        }
        
        return Field(name: name, type: type, optional: optional)
    }
    
}


struct BuilderGenerator {
    
    func generateBuilder(file: String) -> String {
        let structParser = StructParser()
        let parsedStruct = structParser.parseStruct(content: file)
        guard let parsedStruct = parsedStruct else {
            return ""
        }
        var file = "\n"
        file += generateBuilderStruct(str: parsedStruct)
        return file
    }
    
    private func generateBuilderStruct(str: Struct) -> String {
        var builder = ""
        builder += "struct \(str.name)Builder\(str.generics) {\n"
        builder += str.fields.map { field in generateBuilderField(field: field) }.joined(separator: "\n")
        builder += generateBuildFunction(str: str)
        builder += "}\n"
        return builder
    }
    
    private func parseImports(_ file: String) -> [String] {
        // go throw each line
        let lines = file.components(separatedBy: .newlines)
        var imports: [String] = []
        for line in lines {
            // check if line is import
            if line.hasPrefix("import") {
                // add it to imports
                imports.append(line)
            }
        }
        return imports
    }
    
    
    private func getDefaultByType(_ field: Field) -> String {
        if field.type == "String" {
            return "\"\""
        } else if field.type == "Int" {
            return "0"
        } else if field.type == "Float" {
            return "0.0"
        } else if field.type == "Bool" {
            return "false"
        } else if field.type.contains("[") && field.type.contains("]") {
            return "[]"
        } else if field.type == "Array" {
            return "[]"
        } else {
            return "\(field.type)Builder().build()"
        }
    }
    
    private func generateBuilderField(field: Field) -> String {
        var builder = ""
        let defaultValue = getDefaultByType(field)
        if field.optional {
            builder += "\tvar \(field.name): \(field.type)?"
        } else {
            builder += "\tvar \(field.name): \(field.type) = \(defaultValue)"
        }
        return builder
    }
    
    private func generateBuildFunction(str: Struct) -> String {
        var builder = ""
        builder += "\n\tfunc build() -> \(str.name) {\n"
        builder += "\t\treturn \(str.name)(\n"
        builder +=  str.fields.map { field in "\t\t\t\(field.name): \(field.name)" }.joined(separator: ",\n")
        builder += "\n\t\t)"
        builder += "\n\t}\n"
        return builder
    }
    
}




class StructParserTests: XCTestCase {
    
    let singleStruct = """
struct MyProfile: Profile {
    var name: String
    let age: Int
}
"""
    
    func test_parse_struct_should_return_nil_if_file_contains_multiple_structs() throws {
        // arrange
        let content = """
        \(singleStruct)
        \(singleStruct)
        """
        // act
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertNil(resultStruct)
        
    }
    
    func test_parse_struct_should_return_nil_if_file_contains_a_class() throws {
        // arrange
        let content = """
        class MyProfile: Profile {
            var name: String
            var age: Int
        }
        """
        // act
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertNil(resultStruct)
    }
    
    func test_parse_struct_should_contain_name_of_struct() throws {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.name, "MyProfile")
    }
    
    func test_parse_struct_parses_all_fields() throws {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.fields.count, 2)
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
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.fields.count, 2)
    }
    
    func test_parse_struct_parses_correct_field_names() {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.fields[0].name, "name")
        XCTAssertEqual(resultStruct?.fields[1].name, "age")
    }
    
    func test_parse_struct_parses_correct_types() {
        // arrange
        let content = """
        \(singleStruct)
        """
        // act
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.fields[0].type, "String")
        XCTAssertEqual(resultStruct?.fields[1].type, "Int")
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
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.fields[0].optional, false)
        XCTAssertEqual(resultStruct?.fields[1].optional, true)
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
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.fields.count, 2)
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
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.fields[0].name, "name")
        XCTAssertEqual(resultStruct?.fields[1].name, "age")
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
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.fields.count, 2)
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
        let resultStruct = StructParser().parseStruct(content: content)
        // assert
        XCTAssertEqual(resultStruct?.name, "MyProfile")
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
        let result = BuilderGenerator().generateBuilder(file: content)
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
        let result = BuilderGenerator().generateBuilder(file: content)
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
            let isActive: Bool
            let friends: [String]
            let nullableFriends: [String]?
            var nullableName: String?
            var unknown: UnknownStructOrEnum
        }
        """
        // act
        let result = BuilderGenerator().generateBuilder(file: content)
        // assert
        XCTAssertEqual(result.contains("var name: String = \"\""), true)
        XCTAssertEqual(result.contains("var age: Int = 0"), true)
        XCTAssertEqual(result.contains("var height: Float = 0.0"), true)
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
        let result = BuilderGenerator().generateBuilder(file: content)
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
        let result = BuilderGenerator().generateBuilder(file: content)
        // assert
        XCTAssertTrue(result.contains("var items: [T] = []"))
        XCTAssertTrue(result.contains("var paging: ContentPaging?"))
        XCTAssertTrue(result.contains("struct ContentPageBuilder<T:Codable> {"))
    }
    
}
