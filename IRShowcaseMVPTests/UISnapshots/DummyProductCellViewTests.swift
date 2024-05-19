//
//  DummyProductCellViewTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import XCTest
import SwiftUI
import SwiftyMocky
import OrderedCollections

@testable import IRShowcaseMVP

final class DummyProductCellViewTests: TestCase {
    func testDummyProductsListView_NormalState() {
        // Given
        let view = DummyProductCell(
            dummyProduct: .stub()
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }
}

private extension DummyProduct {
    static func stub() -> DummyProduct {
        .init(
            id: 2,
            title: "iPhone X",
            description: "desc",
            price: 899,
            discountPercentage: 17.94,
            rating: 4.44,
            stock: 34,
            brand: "Apple",
            category: "smartphones",
            thumbnail: "",
            images: [""]
        )
    }
}
