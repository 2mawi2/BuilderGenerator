//
//  BuilderGenerator.swift
//  BuilderGenerator
//
//  Created by Marius Wichtner on 06.11.21.
//

import Foundation


struct Field: Codable {
    let name: String
    let type: String
    let optional: Bool
}

struct Struct: Codable {
    let name: String
    let fields: [Field]
}


struct StructParser {
    
    func parseStruct(content: String) -> Struct? {
        if numberOfStructs(content: content) != 1 { return nil }
        var (signature, body) = splitSignatureAndBody(content: content)
        let name = signature.split(separator: ":")[0].trimmingCharacters(in: .whitespaces)
        let fields = parseFields(body: body)
        return Struct(name: name, fields: fields)
    }
    
    private func numberOfStructs(content: String) -> Int {
        return content.components(separatedBy: "struct").count - 1
    }

    private func splitSignatureAndBody(content: String) -> (String, String) {
        var contentFromStruct = content
        if let structRange = content.range(of: "struct") {
            contentFromStruct.removeSubrange(content.startIndex..<structRange.upperBound)
        }
        let indexOfFirstBrace = contentFromStruct.firstIndex(of: "{")!
        let signature = String(contentFromStruct[..<indexOfFirstBrace])
        let body = String(contentFromStruct[indexOfFirstBrace...])
        return (signature, body)
    }
    
    private func parseFields(body: String) -> [Field] {
        var fields = [Field]()
        let lines = body.components(separatedBy: "\n")
        for line in lines {
            if line.contains("var") || line.contains("let") {
                let isComputedProperty = line.contains("{")
                if !isComputedProperty {
                    let field = parseField(line: line)
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
        
        let imports = parseImports(file)
        var file = ""
        for imp in imports {
            file += imp + "\n"
        }
        file += "\n"
        file += generateBuilderStruct(str: parsedStruct)
        return file
    }
    
    func generateBuilderStruct(str: Struct) -> String {
        var builder = ""
        builder += "struct \(str.name)Builder {\n"
        for field in str.fields {
            builder += generateBuilderField(field: field)
        }
        builder += generateBuilderBody(builderFields: str.fields)
        builder += generateBuildFunction(str: str)
        builder += "}\n"
        return builder
    }
    
    func parseImports(_ file: String) -> [String] {
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
    
    
    func getDefaultByType(_ field: Field) -> String {
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
    
    func generateBuilderField(field: Field) -> String {
        var builder = ""
        let defaultValue = getDefaultByType(field)
        if field.optional {
            builder += "var \(field.name): \(field.type)?\n"
        } else {
            builder += "var \(field.name): \(field.type) = \(defaultValue)\n"
        }
        return builder
    }
    
    
    func generateBuilderBody(builderFields: [Field]) -> String {
        return builderFields.map { $0.name }.joined(separator: "\n\t")
    }
    
    func generateBuildFunction(str: Struct) -> String {
        var builder = ""
        builder += "\nfunc build() -> \(str.name) {\n"
        builder += "\treturn \(str.name)(\n"
        for field in str.fields {
            builder += "\t\t\t\(field.name): \(field.name),\n"
        }
        builder += "\n\t\t)"
        builder += "\n\t}"
        return builder
    }
    
}
