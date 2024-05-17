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
            presenter: makePresenter(
                viewModel: .stub()
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }

    func testDummyProductsListView_ErrorView() {
        // Given
        let view = DummyProductsView(
            presenter: makePresenter(
                viewModel: .stub(showErrorView: true)
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }
}

// MARK: - Private methods
private extension DummyProductsListViewTests {
    func makePresenter(viewModel: DummyProductsViewModel) -> DummyProductsViewPresenterMock {
        let presenterMock = DummyProductsViewPresenterMock()

        Given(
            presenterMock,
            .viewModel(getter: viewModel)
        )

        Given(
            presenterMock,
            .onDummyProductTap(
                dummyProduct: .any,
                willReturn: DummyProductDetailsView(
                    presenter: makeDummyProductDetailsViewPresenter(viewModel: .init(dummyProduct: .stub()))
                )
            )
        )

        return presenterMock
    }

    func makeDummyProductDetailsViewPresenter(viewModel: DummyProductDetailsViewModel) -> DummyProductDetailsViewPresenterMock {
        let presenterMock = DummyProductDetailsViewPresenterMock()

        Given(
            presenterMock,
            .viewModel(getter: viewModel)
        )

        return presenterMock
    }
}

private extension DummyProductsViewModel {
    static func stub(showErrorView: Bool = false) -> DummyProductsViewModel {
        let vm = DummyProductsViewModel()

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
