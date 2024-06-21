//
//  DummyProductDetailsViewModel.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class DummyProductDetailsViewObservableObject: ObservableObject {
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
protocol DummyProductDetailsViewModel {
    var observableObject: DummyProductDetailsViewObservableObject { get }
    func onAppear()
}

final class DummyProductDetailsViewModelImpl: DummyProductDetailsViewModel {
    private(set) var routing: DummyProductDetailsScreenRouting
    var observableObject: DummyProductDetailsViewObservableObject

    @MainActor
    init(routing: DummyProductDetailsScreenRouting, dummyProduct: DummyProduct) {
        self.observableObject = DummyProductDetailsViewObservableObject(dummyProduct: dummyProduct)
        self.routing = routing
    }
}

extension DummyProductDetailsViewModelImpl {
    func onAppear() {
        // do nothing
    }
}
