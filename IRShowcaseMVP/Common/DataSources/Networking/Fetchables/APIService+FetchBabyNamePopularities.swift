//
//  APIService+FetchBabyNamePopularities.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension APIServiceImpl: FetchBabyNamePopularitiesProtocol {
    func fetchBabyNamePopularities() async throws -> BabyNamePopularityDataContainer {
        func parseData(_ tuple: (Data, URLResponse)) async throws -> BabyNamePopularityDataContainer {
            try await Task {
                do {
                    let (data, _) = tuple
                    let result = try JSONDecoder().decode(BabyNamePopularityDataContainer.self, from: data)
                    return result
                } catch {
                    throw APIServiceError.parsing(error: error)
                }
            }.value
        }

        let urlRequest = Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: apiBaseUrl)
        let data = try await fetchDataSingle(urlRequest)
        return try await parseData(data)
    }
}
