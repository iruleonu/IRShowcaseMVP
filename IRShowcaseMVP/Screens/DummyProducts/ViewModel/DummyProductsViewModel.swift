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

@MainActor
final class DummyProductsViewObservableObject: ObservableObject, Sendable {
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
    @MainActor func onAppear()
    @MainActor func onItemAppear(_ item: DummyProduct)
    @MainActor func onDummyProductTap(dummyProduct: DummyProduct) -> DummyProductDetailsView
}

// sourcery: AutoMockable
protocol DummyProductsFetchAndSaveDataProvider: FetchDummyProductsProtocol, PersistenceLayerSave {}

final class DummyProductsViewModelImpl: DummyProductsViewModel {
    private let routing: DummyProductsScreenRouting
    private let localDataProvider: DummyProductsFetchAndSaveDataProvider
    private let remoteDataProvider: FetchDummyProductsProtocol
    
    var observableObject: DummyProductsViewObservableObject
    private var cancellables = Set<AnyCancellable>()

    @MainActor
    init(
        routing: DummyProductsScreenRouting,
        localDataProvider: DummyProductsFetchAndSaveDataProvider,
        remoteDataProvider: FetchDummyProductsProtocol
    ) {
        self.routing = routing
        self.localDataProvider = localDataProvider
        self.remoteDataProvider = remoteDataProvider
        self.observableObject = DummyProductsViewObservableObject()
    }
}

extension DummyProductsViewModelImpl {
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

private extension DummyProductsViewModelImpl {
    @MainActor
    func fetchDummyProducts() async {
        guard !observableObject.pagingState.isFetching,
              observableObject.pagingState != .noMorePagesToLoad
        else { return }

        observableObject.pagingState = .loadingFirstPage
        
        // Fetch locally and if error fetch remotely
        let fetchResult: Result<(DummyProductDataContainer, DataProviderSource), Error>
        do {
            let value = try await localDataProvider.fetchDummyProductsAll()
            fetchResult = .success(value)
        } catch {
            do {
                let value = try await remoteDataProvider.fetchDummyProductsAll()
                fetchResult = .success(value)
            } catch {
                fetchResult = .failure(error)
            }
        }

        switch fetchResult {
        case .success(let success):
            let (value, dataProviderSource) = success
            switch dataProviderSource {
            case .remote:
                self.localDataProvider.persistObjects(value) { _, _ in }
            case .local:
                break
            }

            self.observableObject.pagingState = .noMorePagesToLoad
            self.observableObject.dummyProducts = value.products
            print("dataProviderSource: " + dataProviderSource.rawValue)
        case .failure(let error):
            self.observableObject.pagingState = .error
            self.observableObject.errorViewLabel = error.buildString() ?? self.observableObject.errorViewLabel
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
                return "Casting error in the DataProvider on DummyProductsViewModel"
            case .parsing:
                return "Parsing error in the DataProvider on DummyProductsViewModel"
            default:
                return "Error in the DataProvider on DummyProductsViewModel"
            }
        case let errorCast as APIServiceError:
            switch errorCast {
            case .parsing(let error):
                return "Error parsing in the APIService on DummyProductsViewModel: " + error.localizedDescription
            default:
                return "Error in the APIService on DummyProductsViewModel"
            }
        default:
            break
        }

        return nil
    }
}
