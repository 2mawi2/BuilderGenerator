//
//  Foo.swift
//  SourceEditorExtension
//
//  Created by Marius Wichtner on 06.11.21.
//

import Foundation

struct Foo: Equatable {
    var isActive: Bool
    var city: String?
    var countryIsoCode: String? = Locale.current.regionCode
    let aboutMe: String?
    let quote: String?
}
