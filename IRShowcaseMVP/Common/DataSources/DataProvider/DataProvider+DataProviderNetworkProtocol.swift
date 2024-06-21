//
//  DataProvider+DataProviderNetworkProtocol.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 22/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension DataProvider: DataProviderNetworkProtocol {
    func fetchDataPublisher(request: URLRequest) -> AnyPublisher<(Data, URLResponse), DataProviderError> {
        network.fetchDataPublisher(request: request)
    }

    func buildUrlRequest(resource: Resource) -> URLRequest {
        network.buildUrlRequest(resource: resource)
    }

    func fetchData(request: URLRequest) async throws -> (Data, URLResponse) {
        try await network.fetchData(request: request)
    }
}
