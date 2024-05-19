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
}

extension DummyProductsWithHybridDataProviderViewModelImpl {
    func onAppear() {
        fetchDummyProducts()
    }

    func onItemAppear(_ item: DummyProduct) {}

    func onDummyProductTap(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        routing.makeDummyProductDetailsView(dummyProduct: dummyProduct)
    }
}

private extension DummyProductsWithHybridDataProviderViewModelImpl {
    func fetchDummyProducts() {
        guard !observableObject.pagingState.isFetching else { return }
        observableObject.pagingState = .loadingFirstPage

        dataProvider.fetchDummyProductsAll()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self.observableObject.pagingState = .error
                    self.observableObject.showErrorView = true
                }
            }, receiveValue: { [weak self] tuple in
                guard let self = self else { return }
                let (value, dataProviderSource) = tuple

                switch dataProviderSource {
                case .remote:
                    self.dataProvider.persistObjects(value) { _, _ in }
                case .local:
                    break
                }

                self.observableObject.dummyProducts = value.products
                self.observableObject.pagingState = .loaded
                print("dataProviderSource: " + dataProviderSource.rawValue)
            })
            .store(in: &cancellables)
    }
}
