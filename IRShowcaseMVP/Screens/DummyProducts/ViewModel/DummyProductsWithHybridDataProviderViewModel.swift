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

final class DummyProductsWithHybridDataProviderViewModelImpl: DummyProductsViewModel, Sendable {
    private let routing: DummyProductsScreenRouting
    private let dataProvider: DummyProductsFetchAndSaveDataProvider
    let observableObject: DummyProductsViewObservableObject

    @MainActor
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
    @MainActor
    func onAppear() {
        Task { @MainActor in
            await fetchDummyProducts()
        }
    }

    @MainActor
    func onItemAppear(_ item: DummyProduct) {}

    @MainActor
    func onDummyProductTap(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        routing.makeDummyProductDetailsView(dummyProduct: dummyProduct)
    }
}

private extension DummyProductsWithHybridDataProviderViewModelImpl {
    @MainActor
    func fetchDummyProducts() async {
        guard !observableObject.pagingState.isFetching,
              self.observableObject.pagingState != .noMorePagesToLoad
        else { return }

        observableObject.pagingState = .loadingFirstPage

        // Fetch from the dataProvider
        let fetchResult: Result<(DummyProductDataContainer, DataProviderSource), Error>
        do {
            let value = try await dataProvider.fetchDummyProductsAll()
            fetchResult = .success(value)
        } catch {
            fetchResult = .failure(error)
        }

        switch fetchResult {
        case .success(let success):
            let (value, dataProviderSource) = success
            switch dataProviderSource {
            case .remote:
                self.dataProvider.persistObjects(value) { _, _ in }
            case .local:
                break
            }

            self.observableObject.pagingState = .noMorePagesToLoad
            self.observableObject.dummyProducts = value.products
            print("dataProviderSource: " + dataProviderSource.rawValue)
        case .failure(let error):
            self.observableObject.pagingState = .error
            self.observableObject.errorViewLabel = error.buildString() ?? observableObject.errorViewLabel
            self.observableObject.showErrorView = true
        }
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
