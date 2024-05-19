//
//  DummyProductsListViewTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 17/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import XCTest
import SwiftUI
import SwiftyMocky
import OrderedCollections

@testable import IRShowcaseMVP

final class DummyProductsListViewTests: TestCase {
    func testDummyProductsListView_LoadedList() {
        // Given
        let view = DummyProductsView(
            viewModel: makeViewModel(
                observableObject: .stub()
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }

    func testDummyProductsListView_FetchingNewPage() {
        // Given
        let view = DummyProductsView(
            viewModel: makeViewModel(
                observableObject: .stub(
                    showLoadingSpinner: true
                )
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }

    func testDummyProductsListView_ErrorView() {
        // Given
        let view = DummyProductsView(
            viewModel: makeViewModel(
                observableObject: .stub(showErrorView: true)
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }
}

// MARK: - Private methods
private extension DummyProductsListViewTests {
    func makeViewModel(observableObject: DummyProductsViewObservableObject) -> DummyProductsViewModelMock {
        let viewModelMock = DummyProductsViewModelMock()

        Given(
            viewModelMock,
            .observableObject(getter: observableObject)
        )

        Given(
            viewModelMock,
            .onDummyProductTap(
                dummyProduct: .any,
                willReturn: DummyProductDetailsView(
                    viewModel: makeDummyProductDetailsViewPresenter(observableObject: .init(dummyProduct: .stub()))
                )
            )
        )

        return viewModelMock
    }

    func makeDummyProductDetailsViewPresenter(observableObject: DummyProductDetailsViewObservableObject) -> DummyProductDetailsViewModelMock {
        let viewModelMock = DummyProductDetailsViewModelMock()

        Given(
            viewModelMock,
            .observableObject(getter: observableObject)
        )

        return viewModelMock
    }
}

private extension DummyProductsViewObservableObject {
    static func stub(
        showErrorView: Bool = false,
        showLoadingSpinner: Bool = false
    ) -> DummyProductsViewObservableObject {
        let vm = DummyProductsViewObservableObject()

        let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))

        // remove the images so that we only show the placeholder
        var products: [DummyProduct] = []
        dataContainer.products.forEach { product in
            let newProduct = DummyProduct.init(
                id: product.id,
                title: product.title,
                description: product.description,
                price: product.price,
                discountPercentage: product.discountPercentage,
                rating: product.rating,
                stock: product.stock,
                brand: product.brand,
                category: product.category,
                thumbnail: "",
                images: [""]
            )
            products.append(newProduct)
        }
        vm.dummyProducts = products

        vm.showErrorView = showErrorView

        if (showLoadingSpinner) {
            vm.pagingState = .loadingNextPage
        }

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
