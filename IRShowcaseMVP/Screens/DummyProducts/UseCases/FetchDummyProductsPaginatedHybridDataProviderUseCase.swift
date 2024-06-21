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

    func execute(
        dataProvider: DummyProductsFetchAndSaveDataProvider,
        pageSize: Int,
        page: Int
    ) async throws -> (data: (DummyProductDataContainer, DataProviderSource), isLastPage: Bool)
}

struct FetchDummyProductsPaginatedHybridDataProviderUseCaseImpl: FetchDummyProductsPaginatedHybridDataProviderUseCase {
    func execute(
        dataProvider: DummyProductsFetchAndSaveDataProvider,
        pageSize: Int,
        page: Int
    ) -> AnyPublisher<(data: (DummyProductDataContainer, DataProviderSource), isLastPage: Bool), Error> {
        let limit = pageSize
        let skip = page * pageSize
        return dataProvider.fetchDummyProductsPublisher(limit: limit, skip: skip)
            .map({ dummyProductsDataContainer, dataProviderSource in
                let isLastPage = dummyProductsDataContainer.limit + dummyProductsDataContainer.skip >= dummyProductsDataContainer.total
                return ((dummyProductsDataContainer, dataProviderSource), isLastPage)
            })
            .eraseToAnyPublisher()
    }

    func execute(
        dataProvider: DummyProductsFetchAndSaveDataProvider,
        pageSize: Int,
        page: Int
    ) async throws -> (data: (DummyProductDataContainer, DataProviderSource), isLastPage: Bool) {
        let limit = pageSize
        let skip = page * pageSize

        // combine async extension version
        let (dummyProductsDataContainer, dataProviderSource) = try await dataProvider.fetchDummyProductsPublisher(limit: limit, skip: skip).async()
        // async version
        //let (dummyProductsDataContainer, dataProviderSource) = try await dataProvider.fetchDummyProducts(limit: limit, skip: skip)
        let isLastPage = dummyProductsDataContainer.limit + dummyProductsDataContainer.skip + 1 >= dummyProductsDataContainer.total
        return ((dummyProductsDataContainer, dataProviderSource), isLastPage)
    }
}
