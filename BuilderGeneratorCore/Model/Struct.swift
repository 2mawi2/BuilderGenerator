//
//  Struct.swift
//  BuilderGenerator
//
//  Created by Marius Wichtner on 09.11.21.
//

import Foundation

struct Struct: Codable {
    let name: String
    let fields: [Field]
    var generics: String = ""
}
