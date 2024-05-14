//
//  Decodables.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 14/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct FailableDecodable<Base: Decodable> : Decodable {
    let base: Base?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decoded = try? container.decode(Base.self)
        self.base = decoded
    }
}

struct FailableDecodableArray<Element : Codable> : Codable {
    var elements: [Element]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        var elements = [Element]()
        if let count = container.count {
            elements.reserveCapacity(count)
        }

        while !container.isAtEnd {
            if let element = try container.decode(FailableDecodable<Element>.self).base {
                elements.append(element)
                continue
            }

            if (Element.self == String.self) {
                if let element = try container.decode(FailableDecodable<Int>.self).base,
                    let castAsElement = String(element) as? Element {
                    elements.append(castAsElement)
                    continue
                }
            }
        }

        self.elements = elements
    }
}
