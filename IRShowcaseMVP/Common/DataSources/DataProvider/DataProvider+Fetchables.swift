//
//  DataProvider+Fetchables.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension DataProvider: FetchBabyNamePopularitiesProtocol {
    func fetchBabyNamePopularities() -> AnyPublisher<BabyNamePopularityDataContainer, Error> {
        fetchStuff(resource: .babyNamePopularities)
            .tryMap({ elems, _ in
                if let cast = elems as? BabyNamePopularityDataContainer {
                    return cast
                }
                throw DataProviderError.casting
            })
            .mapError({ DataProviderError.fetch(error: $0) })
            .eraseToAnyPublisher()
    }
}

extension DataProvider: FetchDummyProductsProtocol {
    func fetchDummyProducts() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        fetchStuff(resource: .dummyProducts)
            .tryMap({ elems, source in
                if let cast = elems as? DummyProductDataContainer {
                    return (cast, source)
                }
                throw DataProviderError.casting
            })
            .mapError({ DataProviderError.fetch(error: $0) })
            .eraseToAnyPublisher()
    }
}

extension DataProvider: DummyProductsLocalDataProvider {}

