//
//  URLRequestFetchable.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

protocol URLRequestFetchableCombine {
    func fetchDataPublisher(request: URLRequest) -> AnyPublisher<(Data, URLResponse), DataProviderError>
}

protocol URLRequestFetchable: URLRequestFetchableCombine, Sendable {
    func fetchData(request: URLRequest) async throws -> (Data, URLResponse)
}
