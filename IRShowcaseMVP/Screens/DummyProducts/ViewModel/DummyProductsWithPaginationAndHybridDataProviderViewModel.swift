//
//  DummyProductsWithPaginationAndHybridDataProviderViewModel.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import OrderedCollections

final class DummyProductsWithPaginationAndHybridDataProviderViewModelImpl: DummyProductsViewModel {
    let routing: DummyProductsScreenRouting
    let dataProvider: DummyProductsFetchAndSaveDataProvider
    let paginationSize: Int

    var observableObject: DummyProductsViewObservableObject
    let fetchPaginatedDummyProductList: PaginatorSingle<(DummyProductDataContainer, DataProviderSource)>
    let startFetchPublisher: PassthroughSubject<PageFetchType, Never>
    let thresholdToStartFetchingNextPage: Int
    private var cancellables = Set<AnyCancellable>()

    init(
        routing: DummyProductsScreenRouting,
        dataProvider: DummyProductsFetchAndSaveDataProvider,
        paginationSize: Int
    ) {
        self.routing = routing
        self.dataProvider = dataProvider
        self.paginationSize = paginationSize

        self.observableObject = DummyProductsViewObservableObject()

        self.fetchPaginatedDummyProductList = PaginatorSingle(
            useCase: { page in
                FetchDummyProductsPaginatedHybridDataProviderUseCaseImpl()
                    .execute(
                        dataProvider: dataProvider,
                        pageSize: paginationSize,
                        page: page
                    )
            }
        )

        self.startFetchPublisher = PassthroughSubject()
        self.thresholdToStartFetchingNextPage = Constants.DummyProductsThresholdToStartFetchingNextPage

        setupBindings()
    }
}

extension DummyProductsWithPaginationAndHybridDataProviderViewModelImpl {
    func onAppear() {
        startFetchPublisher.send(.initialPage)
    }

    func onItemAppear(_ item: DummyProduct) {
        fetchNextPageIfItemReachedThreshold(item: item, threshold: -abs(thresholdToStartFetchingNextPage))
    }

    func onDummyProductTap(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        return routing.makeDummyProductDetailsView(dummyProduct: dummyProduct)
    }
}

private extension DummyProductsWithPaginationAndHybridDataProviderViewModelImpl {
    func setupBindings() {
        startFetchPublisher
            .buffer(size: 1, prefetch: .byRequest, whenFull: .dropNewest)
            .filter({ [weak self] _ in
                guard let self = self else { return false }
                return !self.observableObject.pagingState.isFetching && self.observableObject.pagingState != .noMorePagesToLoad
            })
            .handleEvents(receiveOutput: { [weak self] output in
                guard let self = self else { return }
                self.observableObject.pagingState = (output == .initialPage) ? .loadingFirstPage : .loadingNextPage
            })
            .fetchPaginatedValue(
                paginator: fetchPaginatedDummyProductList,
                observableObject: observableObject,
                dataProvider: dataProvider
            )
            .store(in: &cancellables)
    }

    func fetchNextPageIfItemReachedThreshold(item: DummyProduct, threshold: Int) {
        // (1) No more pages
        if observableObject.pagingState == .noMorePagesToLoad {
            return
        }

        // (2) Already loading
        if observableObject.pagingState.isFetching {
            return
        }

        // (3) No index
        guard let index = observableObject.dummyProducts.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        // (4) Threshold not reached
        let thresholdIndex = observableObject.dummyProducts.index(observableObject.dummyProducts.endIndex, offsetBy: threshold)
        if index != thresholdIndex {
            return
        }

        // (5) Load next page
        startFetchPublisher.send(.nextPage)
    }
}

private extension Publisher where Output == PageFetchType, Failure == Never {
    func fetchPaginatedValue(
        paginator: PaginatorSingle<(DummyProductDataContainer, DataProviderSource)>,
        observableObject: DummyProductsViewObservableObject,
        dataProvider: DummyProductsFetchAndSaveDataProvider
    ) -> AnyCancellable {
        self.flatMap({ pageFetchType in
            switch pageFetchType {
            case .initialPage:
                return paginator.resetPaginationAndFetchInitialPage()
            case .nextPage:
                return paginator.fetchFollowingPage()
            }
        })
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                observableObject.pagingState = .error
                observableObject.errorViewLabel = error.buildString() ?? observableObject.errorViewLabel
                observableObject.showErrorView = true
            }
        }, receiveValue: { tuple in
            let ((value, dataProviderSource), lastPage) = tuple

            switch dataProviderSource {
            case .remote:
                dataProvider.persistObjects(value) { _, _ in }
            case .local:
                break
            }

            observableObject.pagingState = lastPage ? .noMorePagesToLoad : .loaded
            let orderedSet = OrderedSet(observableObject.dummyProducts).union(value.products)
            observableObject.dummyProducts = Array(orderedSet)
            Swift.print("dataProviderSource: " + dataProviderSource.rawValue)
        })
    }
}

private extension Error {
    func buildString() -> String? {
        switch self {
        case let errorCast as DataProviderError:
            switch errorCast {
            case .casting:
                return "Casting error in the DataProvider on DummyProductsWithPaginationAndHybridDataProviderViewModel"
            case .parsing:
                return "Parsing error in the DataProvider on DummyProductsWithPaginationAndHybridDataProviderViewModel"
            default:
                return "Error in the DataProvider on DummyProductsWithPaginationAndHybridDataProviderViewModel"
            }
        case let errorCast as APIServiceError:
            switch errorCast {
            case .parsing(let error):
                return "Error parsing in the APIService on DummyProductsWithPaginationAndHybridDataProviderViewModel: " + error.localizedDescription
            default:
                return "Error in the APIService on DummyProductsWithPaginationAndHybridDataProviderViewModel"
            }
        default:
            break
        }

        return nil
    }
}
