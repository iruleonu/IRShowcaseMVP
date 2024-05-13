//
//  APIService+FetchBabyNamePopularity.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension APIServiceImpl: FetchBabyNamePopularitiesProtocol {
    func fetchBabyNamePopularities() -> AnyPublisher<[BabyNamePopularity], Error> {
        let properties = Resource.babyNamePopularities.requestProperties
        let urlRequest = URLRequest(url: apiBaseUrl.appendingPathComponent(properties.path))
        func parseData(_ tuple: (Data, URLResponse)) throws -> [BabyNamePopularity] {
            do {
                let (data, _) = tuple
                let result = try JSONDecoder().decode([BabyNamePopularity].self, from: data)
                return result
            } catch {
                throw APIServiceError.parsing(error: error)
            }
        }

        return session.fetchData(urlRequest)
            .tryMap(parseData)
            .eraseToAnyPublisher()
    }
}
