//
//  Expression.swift
//  BuilderGenerator
//
//  Created by Marius Wichtner on 09.11.21.
//

import Foundation

struct Expression {
    var signature: String
    var body: String?
    
    mutating func appendOrSetBody(_ body: String){
        if self.body == nil {
            self.body = ""
        }
        self.body?.append(contentsOf: body)
    }
}
