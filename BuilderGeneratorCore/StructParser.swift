//
//  StructParser.swift
//  BuilderGenerator
//
//  Created by Marius Wichtner on 09.11.21.
//

import Foundation

func parseStructs(content: String) -> [Struct] {
    return parseExpressions(content: content)
        .filter { expression in expression.signature.contains("struct") }
        .compactMap { expression in constructStruct(expression: expression) }
}

private func constructStruct(expression: Expression) -> Struct? {
    let name = parseStructName(expression)
    guard let body = expression.body else { return nil }
    let fields = parseFields(body: body)
    let generics = parseGenerics(str: expression.signature)
    return Struct(name: name, fields: fields, generics: generics)
}

private func parseGenerics(str: String) -> String {
    guard str.contains("<") && str.contains(">") else { return "" }
    let startIndex = str.index(str.startIndex, offsetBy: str.range(of: "<")!.upperBound.utf16Offset(in: str))
    let endIndex = str.index(str.startIndex, offsetBy: str.range(of: ">")!.lowerBound.utf16Offset(in: str))
    let generics = str[startIndex..<endIndex]
    return "<\(String(generics))>"
}

private func parseStructName(_ str: Expression) -> String {
    let signatureWithoutStruct = str.signature.remove("struct")
    let hasGenerics = signatureWithoutStruct.contains("<")
    return signatureWithoutStruct
        .split(separator: hasGenerics ? "<" : ":")[0]
        .trim()
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

private func parseType(_ rawType: String) -> String {
    var type = rawType
    if type.contains("?") {
        type = type.remove("?")
    }
    if type.contains("=") {
        let indexOfEquals = type.firstIndex(of: "=")!
        type = String(type[..<indexOfEquals])
        type = type.trim()
    }
    return type
}

private func parseField(line: String) -> Field {
    let components = line.remove("var").remove("let").components(separatedBy: ":")
    let (name, rawType) = (components[0].trim(), components[1].trim())
    let optional = rawType.contains("?")
    let type = parseType(rawType)
    return Field(name: name, type: type, optional: optional)
}
