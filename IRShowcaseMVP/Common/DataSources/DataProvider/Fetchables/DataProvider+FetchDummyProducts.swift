//
//  DataProvider+FetchDummyProducts.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Combine

extension DataProvider: FetchDummyProductsProtocol {
    func fetchDummyProductsPublisher(limit: Int, skip: Int) -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), any Error> {
        fetchStuffPublisher(resource: .dummyProducts(limit: limit, skip: skip))
                    .tryMap({ elems, source in
                        if let cast = elems as? DummyProductDataContainer {
                            return (cast, source)
                        }
                        throw DataProviderError.casting
                    })
                    .mapError({ DataProviderError.fetch(error: $0) })
                    .eraseToAnyPublisher()
    }
    
    func fetchDummyProductsAllPublisher() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), any Error> {
        // The generic DataProvider only supports one resource at a time (as you can see in the fetchDummyProducts() above)
        // Since the Resource.fetchDummyProductsAll needs to fetch multiple times the Resource.fetchDummyProduct(limit:skip)
        // we need to forward this to the network layer implementation.

        // If any of the layers conforms to the FetchDummyProductsProtocol forward the calls to them
        // If not then the DataProvider is going to use the generic one
        let persistenceLoadPublisher: AnyPublisher<(DummyProductDataContainer, DataProviderSource), DataProviderError>?
        if let persistenceCast = persistence as? FetchDummyProductsProtocol {
            persistenceLoadPublisher = persistenceCast.fetchDummyProductsAllPublisher().mapError({ DataProviderError.fetch(error: $0 )}).eraseToAnyPublisher()
        } else {
            persistenceLoadPublisher = nil
        }

        let remotePublisher: AnyPublisher<(DummyProductDataContainer, DataProviderSource), DataProviderError>?
        if let networkCast = network as? FetchDummyProductsProtocol {
            remotePublisher = networkCast.fetchDummyProductsAllPublisher().mapError({ DataProviderError.fetch(error: $0 )}).eraseToAnyPublisher()
        } else {
            remotePublisher = nil
        }

        return fetchStuffPublisher(
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

    func fetchDummyProducts(limit: Int, skip: Int) async throws -> (DummyProductDataContainer, DataProviderSource) {
        let values = try await fetchStuff(resource: .dummyProducts(limit: limit, skip: skip))
        let castedValues = try values.map { tuple in
            guard let cast = tuple.0 as? DummyProductDataContainer else {
                throw DataProviderError.casting
            }
            return (cast, tuple.1)
        }
        guard let firstValue = castedValues.first else {
            throw DataProviderError.noDataFromFetch
        }
        return firstValue
    }

    @Sendable func fetchDummyProductsAll() async throws -> (DummyProductDataContainer, DataProviderSource) {
        // The generic DataProvider only supports one resource at a time (as you can see in the fetchDummyProducts() above)
        // Since the Resource.fetchDummyProductsAll needs to fetch multiple times the Resource.fetchDummyProduct(limit:skip)
        // we need to forward this to the network layer implementation.

        // If any of the layers conforms to the FetchDummyProductsProtocol forward the calls to them
        // If not then the DataProvider is going to use the generic one

        let persistenceLoad: (@Sendable () async throws -> (DummyProductDataContainer, DataProviderSource))?
        if let persistenceCast = persistence as? FetchDummyProductsProtocol {
            persistenceLoad = persistenceCast.fetchDummyProductsAll
        } else {
            persistenceLoad = nil
        }

        let remote: (@Sendable () async throws -> (DummyProductDataContainer, DataProviderSource))?
        if let networkCast = network as? FetchDummyProductsProtocol {
            remote = networkCast.fetchDummyProductsAll
        } else {
            remote = nil
        }

        let values = try await fetchStuff(
            resource: .dummyProductsAll,
            persistenceLoadProducer: persistenceLoad as? @Sendable () async throws -> (Type, DataProviderSource),
            remoteProducer: (remote as? @Sendable () async throws -> (Type, DataProviderSource)),
            fetchType: .config
        )

        let castedValues = try values.map { tuple in
            guard let cast = tuple.0 as? DummyProductDataContainer else {
                throw DataProviderError.casting
            }
            return (cast, tuple.1)
        }
        guard let firstValue = castedValues.first else {
            throw DataProviderError.noDataFromFetch
        }
        return firstValue
    }
}
