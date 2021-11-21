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
    
    func count(_ subString: String) -> Int {
        return self.trim().components(separatedBy: subString).count - 1
    }
}

extension String.SubSequence {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
}
