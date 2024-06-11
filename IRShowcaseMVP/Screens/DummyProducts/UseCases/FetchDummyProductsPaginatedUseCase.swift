//
//  FetchDummyProductsPaginatedUseCase.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

protocol FetchDummyProductsPaginatedUseCase {
    func execute(
        localDataProvider: DummyProductsFetchAndSaveDataProvider,
        remoteDataProvider: FetchDummyProductsProtocol,
        pageSize: Int,
        page: Int
    ) -> AnyPublisher<(data: (DummyProductDataContainer, DataProviderSource), isLastPage: Bool), Error>
}

struct FetchDummyProductsPaginatedUseCaseImpl: FetchDummyProductsPaginatedUseCase {
    func execute(
        localDataProvider: DummyProductsFetchAndSaveDataProvider,
        remoteDataProvider: FetchDummyProductsProtocol,
        pageSize: Int,
        page: Int
    ) -> AnyPublisher<(data: (DummyProductDataContainer, DataProviderSource), isLastPage: Bool), Error> {
        let limit = pageSize
        let skip = page * pageSize
        return localDataProvider.fetchDummyProducts(limit: limit, skip: skip)
            .map({ dummyProductsDataContainer, dataProviderSource in
                let isLastPage = dummyProductsDataContainer.limit + dummyProductsDataContainer.skip + 1 >= dummyProductsDataContainer.total
                return ((dummyProductsDataContainer, dataProviderSource), isLastPage)
            })
            .catch({ _ in
                return remoteDataProvider.fetchDummyProducts(limit: limit, skip: skip)
                    .map({ dummyProductsDataContainer, dataProviderSource in
                        let isLastPage = dummyProductsDataContainer.limit + dummyProductsDataContainer.skip + 1 >= dummyProductsDataContainer.total
                        return ((dummyProductsDataContainer, dataProviderSource), isLastPage)
                    })
            })
            .eraseToAnyPublisher()
    }
}
