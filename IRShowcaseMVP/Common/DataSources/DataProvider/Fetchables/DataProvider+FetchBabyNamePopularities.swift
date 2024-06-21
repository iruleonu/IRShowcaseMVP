//
//  DataProvider+FetchBabyNamePopularities.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

extension DataProvider: FetchBabyNamePopularitiesProtocol {
    func fetchBabyNamePopularities() async throws -> BabyNamePopularityDataContainer {
        let values = try await fetchStuff(resource: .babyNamePopularities)
        let castedValuesWithoutSource = try values.map { tuple in
            guard let cast = tuple.0 as? BabyNamePopularityDataContainer else {
                throw DataProviderError.casting
            }
            return cast
        }
        guard let firstValue = castedValuesWithoutSource.first else {
            throw DataProviderError.noDataFromFetch
        }

        return firstValue
    }
}
