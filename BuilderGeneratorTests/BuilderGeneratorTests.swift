import XCTest
import Foundation

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
    
    func parseStructs(content: String ) -> [Struct] {
        return parseExpressions(content: content)
            .filter { expression in expression.signature.contains("struct") }
            .compactMap { expression in constructStruct(expression: expression) }
    }
    
    private func constructStruct(expression: Expression) -> Struct? {
        let name = parseStructName(expression)
        guard let body = expression.body else {
            return nil
        }
        let fields = parseFields(body: body)
        let generics = parseGenerics(str: expression)
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
        return signatureWithoutStruct
            .split(separator: hasGenerics ? "<" : ":")[0]
            .trimmingCharacters(in: .whitespaces)
        
    }
    
    private func numberOfStructs(content: String) -> Int {
        return content.components(separatedBy: "struct").count - 1
    }
    
    private func parseFields(body: String) -> [Field] {
        var fields = [Field]()
        let bodyWithoutEnclosingBrackets = body
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
    
    func generateBuilders(file: String) -> String {
        let structParser = StructParser()
        let parsedStructs = structParser.parseStructs(content: file)
        if parsedStructs.isEmpty {
            return ""
        }
        var file = "\n"
        for parsedStruct in parsedStructs {
            file += generateBuilderStruct(str: parsedStruct)
            file += "\n"
        }
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
        } else if field.type == "Float" || field.type == "Double" {
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
