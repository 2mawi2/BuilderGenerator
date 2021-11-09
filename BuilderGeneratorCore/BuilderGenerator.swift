//
//  BuilderGenerator.swift
//  BuilderGenerator
//
//  Created by Marius Wichtner on 06.11.21.
//

import Foundation

func generateBuilders(file: String) -> String {
    let parsedStructs = parseStructs(content: file)
    if parsedStructs.isEmpty {
        return ""
    }
    return generateFileWithAllBuilders(parsedStructs)
}

private func generateFileWithAllBuilders(_ parsedStructs: [Struct]) -> String {
    var file = "\n"
    for parsedStruct in parsedStructs {
        file += generateBuilderStruct(str: parsedStruct)
        file += "\n"
    }
    return file
}


private func generateBuilderStruct(str: Struct) -> String {
    var builder = "struct \(str.name)Builder\(str.generics) {\n"
    builder += str.fields.map { field in generateBuilderField(field: field) }.joined(separator: "\n")
    builder += generateBuildFunction(str: str)
    builder += "}\n"
    return builder
}

private func parseImports(_ file: String) -> [String] {
    return file
        .components(separatedBy: .newlines)
        .filter { $0.hasPrefix("import") }
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
    var builder = "\tvar \(field.name): \(field.type)"
    builder += field.optional ? "?" : " = \(getDefaultByType(field))"
    return builder
}

private func generateBuildFunction(str: Struct) -> String {
    var builder = "\n\tfunc build() -> \(str.name) {\n"
    builder += "\t\treturn \(str.name)(\n"
    builder +=  str.fields.map { field in "\t\t\t\(field.name): \(field.name)" }.joined(separator: ",\n")
    builder += "\n\t\t)"
    builder += "\n\t}\n"
    return builder
}



