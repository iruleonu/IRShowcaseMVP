//
//  DummyProductsWithHybridDataProviderViewModel.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 17/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class DummyProductsWithHybridDataProviderViewModelImpl: DummyProductsViewModel {
    private let routing: DummyProductsScreenRouting
    private let dataProvider: DummyProductsLocalDataProvider
    var observableObject: DummyProductsViewObservableObject

    private var cancellables = Set<AnyCancellable>()

    init(
        routing: DummyProductsScreenRouting,
        dataProvider: DummyProductsLocalDataProvider
    ) {
        self.routing = routing
        self.dataProvider = dataProvider
        self.observableObject = DummyProductsViewObservableObject()
    }

    func onAppear() {
        fetchDummyProducts()
    }

    private func fetchDummyProducts() {
        dataProvider.fetchDummyProducts()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self.observableObject.showErrorView = true
                }
            }, receiveValue: { [weak self] tuple in
                guard let self = self else { return }
                let (value, dataProviderSource) = tuple
                self.dataProvider.persistObjects(value) { _, _ in }
                self.observableObject.dummyProducts = value.products
                print("dataProviderSource: " + dataProviderSource.rawValue)
            })
            .store(in: &cancellables)
    }
}

extension DummyProductsWithHybridDataProviderViewModelImpl {
    func onDummyProductTap(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        return self.routing.makeDummyProductDetailsView(dummyProduct: dummyProduct)
    }
}
