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
    private let dataProvider: DummyProductsFetchAndSaveDataProvider
    var observableObject: DummyProductsViewObservableObject

    private var cancellables = Set<AnyCancellable>()

    init(
        routing: DummyProductsScreenRouting,
        dataProvider: DummyProductsFetchAndSaveDataProvider
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
        guard !observableObject.pagingState.isFetching,
              self.observableObject.pagingState != .noMorePagesToLoad
        else { return }

        observableObject.pagingState = .loadingFirstPage

        dataProvider.fetchDummyProductsAll()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.observableObject.pagingState = .error
                    self.observableObject.errorViewLabel = error.buildString() ?? observableObject.errorViewLabel
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

                self.observableObject.pagingState = .noMorePagesToLoad
                self.observableObject.dummyProducts = value.products
                print("dataProviderSource: " + dataProviderSource.rawValue)
            })
            .store(in: &cancellables)
    }
}

private extension Error {
    func buildString() -> String? {
        switch self {
        case let errorCast as DataProviderError:
            switch errorCast {
            case .casting:
                return "Casting error in the DataProvider on DummyProductsWithHybridDataProviderViewModel"
            case .parsing:
                return "Parsing error in the DataProvider on DummyProductsWithHybridDataProviderViewModel"
            default:
                return "Error in the DataProvider on DummyProductsWithHybridDataProviderViewModel"
            }
        case let errorCast as APIServiceError:
            switch errorCast {
            case .parsing(let error):
                return "Error parsing in the APIService on DummyProductsWithHybridDataProviderViewModel: " + error.localizedDescription
            default:
                return "Error in the APIService on DummyProductsWithHybridDataProviderViewModel"
            }
        default:
            break
        }

        return nil
    }
}
