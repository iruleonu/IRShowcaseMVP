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
    func fetchData(_ request: URLRequest) -> AnyPublisher<(Data, URLResponse), DataProviderError> {
        Future { promise in
            self.dataTask(with: request) { data, response, error in
                guard let data = data, let response = response else {
                    guard let e = error else {
                        promise(.failure(.unknown))
                        return
                    }
                    promise(.failure(.requestError(error: e)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    promise(.failure(.unknown))
                    return
                }

                guard 200..<300 ~= httpResponse.statusCode else {
                    promise(.failure(.requestError(httpStatusCode: httpResponse.statusCode, error: error)))
                    return
                }

                promise(.success((data, httpResponse)))
            }
            .resume()
        }
        .eraseToAnyPublisher()
    }
}
