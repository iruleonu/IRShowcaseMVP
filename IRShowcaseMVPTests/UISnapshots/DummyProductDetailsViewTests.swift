//
//  DummyProductDetailsViewTests.swift
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

final class DummyProductDetailsViewTests: TestCase {
    func testDummyProductDetailsView_ViewWithProduct() {
        // Given
        let view = DummyProductDetailsView(
            viewModel: makeViewModel(
                observableObject: .stub(
                    dummyProduct: .stub()
                )
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }
}

// MARK: - Private methods
private extension DummyProductDetailsViewTests {
    func makeViewModel(observableObject: DummyProductDetailsViewObservableObject) -> DummyProductDetailsViewModelMock {
        let viewModelMock = DummyProductDetailsViewModelMock()

        Given(
            viewModelMock,
            .observableObject(getter: observableObject)
        )

        return viewModelMock
    }
}

private extension DummyProductDetailsViewObservableObject {
    static func stub(
        dummyProduct: DummyProduct
    ) -> DummyProductDetailsViewObservableObject {
        let vm = DummyProductDetailsViewObservableObject(dummyProduct: dummyProduct)
        return vm
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
