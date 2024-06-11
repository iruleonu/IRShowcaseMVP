//
//  FetchDummyProductsPaginatedHybridDataProviderUseCase.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

protocol FetchDummyProductsPaginatedHybridDataProviderUseCase {
    func execute(
        dataProvider: DummyProductsFetchAndSaveDataProvider,
        pageSize: Int,
        page: Int
    ) -> AnyPublisher<(data: (DummyProductDataContainer, DataProviderSource), isLastPage: Bool), Error>
}

struct FetchDummyProductsPaginatedHybridDataProviderUseCaseImpl: FetchDummyProductsPaginatedHybridDataProviderUseCase {
    func execute(
        dataProvider: DummyProductsFetchAndSaveDataProvider,
        pageSize: Int,
        page: Int
    ) -> AnyPublisher<(data: (DummyProductDataContainer, DataProviderSource), isLastPage: Bool), Error> {
        let limit = pageSize
        let skip = page * pageSize
        return dataProvider.fetchDummyProducts(limit: limit, skip: skip)
            .map({ dummyProductsDataContainer, dataProviderSource in
                let isLastPage = dummyProductsDataContainer.limit + dummyProductsDataContainer.skip >= dummyProductsDataContainer.total
                return ((dummyProductsDataContainer, dataProviderSource), isLastPage)
            })
            .eraseToAnyPublisher()
    }
}
