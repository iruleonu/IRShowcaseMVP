//
//  APIService+URLRequestFetchable.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension APIServiceImpl: URLRequestFetchable {
    func fetchDataPublisher(request: URLRequest) -> AnyPublisher<(Data, URLResponse), DataProviderError> {
        session.fetchDataPublisher(request)
    }

    func fetchData(request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.fetchData(request)
    }
}
