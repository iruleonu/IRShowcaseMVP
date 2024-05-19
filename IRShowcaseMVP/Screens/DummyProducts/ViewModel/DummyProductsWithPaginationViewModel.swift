//
//  DummyProductsWithPaginationViewModel.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class DummyProductsWithPaginationViewModelImpl: DummyProductsViewModel {
    let routing: DummyProductsScreenRouting
    let localDataProvider: DummyProductsLocalDataProvider
    let remoteDataProvider: FetchDummyProductsProtocol
    let paginationSize: Int

    var observableObject: DummyProductsViewObservableObject
    let fetchPaginatedDummyProductList: PaginatorSingle<(DummyProductDataContainer, DataProviderSource)>
    let startFetchPublisher: PassthroughSubject<PageFetchType, Never>
    let thresholdToStartFetchingNextPage: Int
    private var cancellables = Set<AnyCancellable>()

    init(
        routing: DummyProductsScreenRouting,
        localDataProvider: DummyProductsLocalDataProvider,
        remoteDataProvider: FetchDummyProductsProtocol,
        paginationSize: Int
    ) {
        self.routing = routing
        self.localDataProvider = localDataProvider
        self.remoteDataProvider = remoteDataProvider
        self.paginationSize = paginationSize

        self.observableObject = DummyProductsViewObservableObject()

        self.fetchPaginatedDummyProductList = PaginatorSingle(
            useCase: { page in
                FetchDummyProductsPaginatedUseCaseImpl()
                    .execute(
                        localDataProvider: localDataProvider,
                        remoteDataProvider: remoteDataProvider, 
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

extension DummyProductsWithPaginationViewModelImpl {
    func onAppear() {
        startFetchPublisher.send(.initialPage)
    }

    func onItemAppear(_ item: DummyProduct) {
        fetchNextPageIfItemReachedThreshold(item: item, threshold: -abs(thresholdToStartFetchingNextPage))
    }

    func onDummyProductTap(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        return self.routing.makeDummyProductDetailsView(dummyProduct: dummyProduct)
    }
}

private extension DummyProductsWithPaginationViewModelImpl {
    func setupBindings() {
        startFetchPublisher
            .buffer(size: 1, prefetch: .byRequest, whenFull: .dropNewest)
            .handleEvents(receiveOutput: { output in
                guard self.observableObject.pagingState != .noMorePagesToLoad else { return }
                self.observableObject.pagingState = (output == .initialPage) ? .loadingFirstPage : .loadingNextPage
            })
            .fetchPaginatedValue(
                paginator: fetchPaginatedDummyProductList,
                observableObject: observableObject,
                localDataProvider: localDataProvider
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
        localDataProvider: DummyProductsLocalDataProvider
    ) -> AnyCancellable {
        self.compactMap({ return observableObject.pagingState != .loaded ? $0 : nil })
        .flatMap({ pageFetchType in
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
            case .failure:
                observableObject.pagingState = .error
                observableObject.showErrorView = true
            }
        }, receiveValue: { tuple in
            let ((value, dataProviderSource), lastPage) = tuple

            switch dataProviderSource {
            case .remote:
                localDataProvider.persistObjects(value) { _, _ in }
            case .local:
                break
            }

            observableObject.dummyProducts = observableObject.dummyProducts + value.products
            observableObject.pagingState = lastPage ? .noMorePagesToLoad : .loaded
            Swift.print("dataProviderSource: " + dataProviderSource.rawValue)
        })
    }
}
