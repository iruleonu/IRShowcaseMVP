//
//  APIService+FetchDummyProducts.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension APIServiceImpl: FetchDummyProductsProtocol {
    func fetchDummyProducts(limit: Int, skip: Int) async throws -> (DummyProductDataContainer, DataProviderSource) {
        func parseData(_ tuple: (Data, URLResponse)) async throws -> DummyProductDataContainer {
            try await Task {
                do {
                    let (data, _) = tuple
                    let result = try JSONDecoder().decode(DummyProductDataContainer.self, from: data)
                    return result
                } catch {
                    throw APIServiceError.parsing(error: error)
                }
            }.value
        }

        let urlRequest = Resource.dummyProducts(limit: limit, skip: skip).buildUrlRequest(apiBaseUrl: apiBaseUrl)
        let data = try await fetchDataSingle(urlRequest)
        return (try await parseData(data), .remote)
    }

    @Sendable
    func fetchDummyProductsAll() async throws -> (DummyProductDataContainer, DataProviderSource) {
        var cancellables = Set<AnyCancellable>()
        return try await withCheckedThrowingContinuation { continuation in
            fetchDummyProductsAllPaginatedPublisher()
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                } receiveValue: { value in
                    continuation.resume(returning: value)
                }
                .store(in: &cancellables)
        }
    }

    func fetchDummyProductsPublisher(limit: Int, skip: Int) -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        let urlRequest = Resource.dummyProducts(limit: limit, skip: skip).buildUrlRequest(apiBaseUrl: apiBaseUrl)

        func parseData(_ tuple: (Data, URLResponse)) throws -> DummyProductDataContainer {
            do {
                let (data, _) = tuple
                let result = try JSONDecoder().decode(DummyProductDataContainer.self, from: data)
                return result
            } catch {
                throw APIServiceError.parsing(error: error)
            }
        }

        return fetchDataPublisher(urlRequest)
            .tryMap(parseData)
            .map({ ($0, .remote) })
            .eraseToAnyPublisher()
    }

    func fetchDummyProductsAllPublisher() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        fetchDummyProductsAllPaginatedPublisher()
    }
}

private extension APIServiceImpl {
    func fetchDummyProductsAllPaginatedPublisher() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        let skipNumberApiQueryParamPublisher = CurrentValueSubject<Int, Never>(0)
        return skipNumberApiQueryParamPublisher
            .flatMap({ pageIndex in
                self.fetchDummyProductsPublisher(limit: Constants.DummyProductsAPIPageSize, skip: pageIndex).eraseToAnyPublisher()
            })
            .handleEvents(receiveOutput: { tuple in
                let (fetchedPage, _) = tuple
                let totalFetched = fetchedPage.skip + fetchedPage.limit
                let hasMorePages = totalFetched < fetchedPage.total
                if hasMorePages {
                    skipNumberApiQueryParamPublisher.send(totalFetched)
                } else {
                    skipNumberApiQueryParamPublisher.send(completion: .finished)
                }
            })
            .map({ $0.0 })
            .reduce(DummyProductDataContainer(total: 0, skip: 0, limit: 0, products: []), { currentDataContainer, fetchedDataContainer in
                return DummyProductDataContainer(
                    total: fetchedDataContainer.total,
                    skip: fetchedDataContainer.skip,
                    limit: fetchedDataContainer.limit,
                    products: currentDataContainer.products + fetchedDataContainer.products
                )
            })
            .map({ ($0, .remote )})
            .eraseToAnyPublisher()
    }
}
