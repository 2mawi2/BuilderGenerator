//
//  BuilderGenerator.swift
//  BuilderGenerator
//
//  Created by Marius Wichtner on 06.11.21.
//

import Foundation

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

