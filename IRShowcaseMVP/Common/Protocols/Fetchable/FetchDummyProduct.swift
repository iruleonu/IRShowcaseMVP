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
protocol FetchDummyProductsProtocol {
    func fetchDummyProducts() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error>
}
