//
//  FetchDummyProducts.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Foundation
import Combine

// sourcery: AutoMockable
protocol FetchDummyProductsCombineProtocol {
    func fetchDummyProductsPublisher(limit: Int, skip: Int) -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error>
    func fetchDummyProductsAllPublisher() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error>
}

// sourcery: AutoMockable
protocol FetchDummyProductsProtocol: FetchDummyProductsCombineProtocol, Sendable {
    @Sendable func fetchDummyProducts(limit: Int, skip: Int) async throws -> (DummyProductDataContainer, DataProviderSource)
    @Sendable func fetchDummyProductsAll() async throws -> (DummyProductDataContainer, DataProviderSource)
}
