//
//  BuilderGeneratorApp.swift
//  BuilderGenerator
//
//  Created by Marius Wichtner on 06.11.21.
//

import SwiftUI

@main
struct BuilderGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct FileParser {
    func parse(fileContent: String) -> String? {
        let structs = fileContent.components(separatedBy: "struct")
        if structs.count > 2 {
            print("multiple structs in file")
            return nil
        }
        if fileContent.contains("class") {
            print("class not supported")
            return nil
        }
        let signature = structs[1].components(separatedBy: "{")[0]
        let nameAndProtocols = removeStruct(signature)
        let name = extractName(nameAndProtocols)
        return name
    }

    private func removeStruct(_ signature: String) -> String {
        return signature.components(separatedBy: "struct")[1].trimmingCharacters(in: .whitespaces)
    }

    private func extractName(_ name: String) -> String {
        return name.components(separatedBy: ":")[0].trimmingCharacters(in: .whitespaces)
    }
}

