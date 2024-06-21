//
//  URLSession.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 21/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension URLSession {
    func fetchDataPublisher(_ request: URLRequest) -> AnyPublisher<(Data, URLResponse), DataProviderError> {
        return self.dataTaskPublisher(for: request)
            .subscribe(on: DispatchQueue.global())
            .tryMap { value -> (Data, URLResponse) in
                let data = value.data
                let response = value.response

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw DataProviderError.unknown
                }

                guard 200..<300 ~= httpResponse.statusCode else {
                    throw DataProviderError.unknown
                }

                return (data, httpResponse)
            }
            .mapError { error in
                DataProviderError.fetch(error: error)
            }
            .eraseToAnyPublisher()
    }
}

extension URLSession {
    func fetchData(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = try await self.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DataProviderError.invalidHttpUrlResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw DataProviderError.requestHttpStatusError(httpStatusCode: httpResponse.statusCode, error: nil)
        }

        return (data, httpResponse)
    }
}
