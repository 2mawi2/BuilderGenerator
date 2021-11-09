//
//  String+trim.swift
//  BuilderGenerator
//
//  Created by Marius Wichtner on 09.11.21.
//

import Foundation

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func remove(_ subString: String) -> String {
        return self.replacingOccurrences(of: subString, with: "")
    }
}

extension String.SubSequence {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
