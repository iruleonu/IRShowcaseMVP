//
//  PersistenceLayer+Fetchables.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension PersistenceLayerImpl: FetchBabyNamePopularitiesProtocol {
    func fetchBabyNamePopularities() -> AnyPublisher<BabyNamePopularityDataContainer, Error> {
        return self.fetchResource(.babyNamePopularities)
            .mapError({ PersistenceLayerError.persistence(error: $0) })
            .eraseToAnyPublisher()
    }
}

extension PersistenceLayerImpl: FetchDummyProductsProtocol {
    func fetchDummyProducts(limit: Int, skip: Int) -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        return self.fetchResource(.dummyProducts(limit: limit, skip: skip))
            .mapError({ PersistenceLayerError.persistence(error: $0) })
            .map({ ($0, .local) })
            .eraseToAnyPublisher()
    }

    func fetchDummyProductsAll() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        return self.fetchResource(.dummyProductsAll)
            .mapError({ PersistenceLayerError.persistence(error: $0) })
            .map({ ($0, .local) })
            .eraseToAnyPublisher()
    }
}

extension PersistenceLayerImpl: DummyProductsFetchAndSaveDataProvider {}
