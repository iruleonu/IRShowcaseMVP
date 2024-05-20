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
    @Published var pagingState: PagingState = .unknown
}

// sourcery: AutoMockable
protocol DummyProductsViewModel {
    var observableObject: DummyProductsViewObservableObject { get }
    func onAppear()
    func onItemAppear(_ item: DummyProduct)
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
}

extension DummyProductsViewModelImpl {
    func onAppear() {
        fetchDummyProducts()
    }

    func onItemAppear(_ item: DummyProduct) {}

    func onDummyProductTap(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        routing.makeDummyProductDetailsView(dummyProduct: dummyProduct)
    }
}

private extension DummyProductsViewModelImpl {
    func fetchDummyProducts() {
        guard !observableObject.pagingState.isFetching,
              self.observableObject.pagingState != .noMorePagesToLoad
        else { return }

        observableObject.pagingState = .loadingFirstPage

        localDataProvider.fetchDummyProductsAll()
            .catch({ [weak self] _ in
                guard let self = self else { return Empty<(DummyProductDataContainer, DataProviderSource), Error>().eraseToAnyPublisher() }
                return self.remoteDataProvider.fetchDummyProductsAll().eraseToAnyPublisher()
            })
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

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
                    self.localDataProvider.persistObjects(value) { _, _ in }
                case .local:
                    break
                }

                self.observableObject.pagingState = .noMorePagesToLoad
                self.observableObject.dummyProducts = value.products
                print("dataProviderSource: " + dataProviderSource.rawValue)
            })
            .store(in: &cancellables)
    }
}
