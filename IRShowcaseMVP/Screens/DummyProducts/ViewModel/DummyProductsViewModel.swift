//
//  DummyProductsViewViewModel.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class DummyProductsViewObservableObject: ObservableObject {
    let navBarTitle = "Dummy products list"
    @Published var dummyProducts: [DummyProduct] = []
    @Published var selectedDummyProduct: DummyProduct?
    @Published var showErrorView: Bool = false
    @Published var errorViewLabel: String = "Nothing to see"
}

// sourcery: AutoMockable
protocol DummyProductsViewModel {
    var observableObject: DummyProductsViewObservableObject { get }
    func onAppear()
    func onDummyProductTap(dummyProduct: DummyProduct) -> DummyProductDetailsView
}

// sourcery: AutoMockable
protocol DummyProductsLocalDataProvider: FetchDummyProductsProtocol, PersistenceLayerSave {}

final class DummyProductsViewModelImpl: DummyProductsViewModel {
    private let routing: DummyProductsScreenRouting
    private let localDataProvider: DummyProductsLocalDataProvider
    private let remoteDataProvider: FetchDummyProductsProtocol
    var observableObject: DummyProductsViewObservableObject

    private var cancellables = Set<AnyCancellable>()

    init(
        routing: DummyProductsScreenRouting,
        localDataProvider: DummyProductsLocalDataProvider,
        remoteDataProvider: FetchDummyProductsProtocol
    ) {
        self.routing = routing
        self.localDataProvider = localDataProvider
        self.remoteDataProvider = remoteDataProvider
        self.observableObject = DummyProductsViewObservableObject()
    }

    func onAppear() {
        fetchDummyProducts()
    }

    private func fetchDummyProducts() {
        localDataProvider.fetchDummyProducts()
            .catch({ _ in
                return self.remoteDataProvider.fetchDummyProducts().eraseToAnyPublisher()
            })
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
                self.localDataProvider.persistObjects(value) { _, _ in }
                self.observableObject.dummyProducts = value.products
                print("dataProviderSource: " + dataProviderSource.rawValue)
            })
            .store(in: &cancellables)
    }
}

extension DummyProductsViewModelImpl {
    func onDummyProductTap(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        return self.routing.makeDummyProductDetailsView(dummyProduct: dummyProduct)
    }
}
