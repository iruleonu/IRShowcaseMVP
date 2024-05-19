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
    func fetchDummyProducts(limit: Int, skip: Int) -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        fetchStuff(resource: .dummyProducts(limit: limit, skip: skip))
            .tryMap({ elems, source in
                if let cast = elems as? DummyProductDataContainer {
                    return (cast, source)
                }
                throw DataProviderError.casting
            })
            .mapError({ DataProviderError.fetch(error: $0) })
            .eraseToAnyPublisher()
    }

    func fetchDummyProductsAll() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        // The generic DataProvider only supports one resource at a time (as you can see in the fetchDummyProducts() above)
        // Since the Resource.fetchDummyProductsAll needs to fetch multiple times the Resource.fetchDummyProduct(limit:skip)
        // we need to forward this to the network layer implementation.

        // If any of the layers conforms to the FetchDummyProductsProtocol forward the calls to them
        // If not then the DataProvider is going to use the generic one
        let persistenceLoadPublisher: AnyPublisher<(DummyProductDataContainer, DataProviderSource), DataProviderError>?
        if let persistenceCast = persistence as? FetchDummyProductsProtocol {
            persistenceLoadPublisher = persistenceCast.fetchDummyProductsAll().mapError({ DataProviderError.fetch(error: $0 )}).eraseToAnyPublisher()
        } else {
            persistenceLoadPublisher = nil
        }

        let remotePublisher: AnyPublisher<(DummyProductDataContainer, DataProviderSource), DataProviderError>?
        if let networkCast = network as? FetchDummyProductsProtocol {
            remotePublisher = networkCast.fetchDummyProductsAll().mapError({ DataProviderError.fetch(error: $0 )}).eraseToAnyPublisher()
        } else {
            remotePublisher = nil
        }

        return fetchStuff(
            resource: .dummyProductsAll,
            persistenceLoadProducer: persistenceLoadPublisher as? AnyPublisher<(Type, DataProviderSource), DataProviderError>,
            remoteProducer: remotePublisher as? AnyPublisher<(Type, DataProviderSource), DataProviderError>,
            fetchType: .config
        )
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
