//
//  DummyProductDataContainer.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct DummyProductDataContainer: Codable {
    let total: Int
    let skip: Int
    let limit: Int
    let products: [DummyProduct]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let total = try container.decode(Int.self, forKey: .total)
        let skip = try container.decode(Int.self, forKey: .skip)
        let limit = try container.decode(Int.self, forKey: .limit)
        let products = try container.decode([DummyProduct].self, forKey: .products)
        self.init(
            total: total,
            skip: skip,
            limit: limit,
            products: products
        )
    }

    init(
        total: Int,
        skip: Int,
        limit: Int,
        products: [DummyProduct]
    ) {
        self.total = total
        self.skip = skip
        self.limit = limit
        self.products = products
    }
}

extension DummyProductDataContainer: Equatable {
    static func == (left: DummyProductDataContainer, right: DummyProductDataContainer) -> Bool {
        return left.total == right.total
        && left.skip == right.skip
        && left.limit == right.limit
        && left.products == right.products
    }
}
