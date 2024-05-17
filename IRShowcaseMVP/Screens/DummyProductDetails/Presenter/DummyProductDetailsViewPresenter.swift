//
//  DummyProductDetailsPresenter.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class DummyProductDetailsViewModel: ObservableObject {
    @Published var title: String
    @Published var price: String
    @Published var discountPercentage: String
    @Published var stock: String
    @Published var imageBasedOnProductRating: String
    @Published var rating: String

    init(dummyProduct: DummyProduct) {
        self.title = dummyProduct.title
        self.price = String(dummyProduct.price)
        self.discountPercentage = String(dummyProduct.discountPercentage)
        self.stock = String(dummyProduct.stock)
        self.imageBasedOnProductRating = dummyProduct.imageBasedOnProductRating
        self.rating = String(dummyProduct.rating)
    }
}

// sourcery: AutoMockable
protocol DummyProductDetailsViewPresenter {
    var viewModel: DummyProductDetailsViewModel { get }
    func onAppear()
}

final class DummyProductDetailsViewPresenterImpl: DummyProductDetailsViewPresenter {
    var viewModel: DummyProductDetailsViewModel
    private(set) var routing: DummyProductDetailsScreenRouting

    init(routing: DummyProductDetailsScreenRouting, dummyProduct: DummyProduct) {
        self.viewModel = DummyProductDetailsViewModel(dummyProduct: dummyProduct)
        self.routing = routing
    }

    func onAppear() {
        // do nothing
    }
}
