//
//  PersistenceLayer+FetchDummyProducts.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension PersistenceLayerImpl: FetchDummyProductsProtocol {
    func fetchDummyProductsPublisher(limit: Int, skip: Int) -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), any Error> {
        return self.fetchResourcePublisher(.dummyProducts(limit: limit, skip: skip))
            .mapError({ PersistenceLayerError.persistence(error: $0) })
            .map({ ($0, .local) })
            .eraseToAnyPublisher()
    }
    
    func fetchDummyProductsAllPublisher() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), any Error> {
        return self.fetchResourcePublisher(.dummyProductsAll)
            .mapError({ PersistenceLayerError.persistence(error: $0) })
            .map({ ($0, .local) })
            .eraseToAnyPublisher()
    }
    
    func fetchDummyProducts(limit: Int, skip: Int) async throws -> (DummyProductDataContainer, DataProviderSource) {
        do {
            let values: DummyProductDataContainer = try await self.fetchResource(.dummyProducts(limit: limit, skip: skip))
            return (values, .local)
        } catch {
            throw PersistenceLayerError.persistence(error: error)
        }
    }

    func fetchDummyProductsAll() async throws -> (DummyProductDataContainer, DataProviderSource) {
        do {
            let values: DummyProductDataContainer = try await self.fetchResource(.dummyProductsAll)
            return (values, .local)
        } catch {
            throw PersistenceLayerError.persistence(error: error)
        }
    }
}
