//
//  APIService+Fetchable.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension APIServiceImpl: Fetchable {
    typealias I = URLRequest
    typealias V = (Data, URLResponse)
    typealias E = DataProviderError

    func fetchDataSingle(_ input: URLRequest) async throws -> (Data, URLResponse) {
        try await session.fetchData(input)
    }

    func fetchData(_ input: URLRequest) async throws -> [(Data, URLResponse)] {
        [try await session.fetchData(input)]
    }

    func fetchDataPublisher(_ input: I) -> AnyPublisher<V, E> {
        return session.fetchDataPublisher(input)
    }
}
