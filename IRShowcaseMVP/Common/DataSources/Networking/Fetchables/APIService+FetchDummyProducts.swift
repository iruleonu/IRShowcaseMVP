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
        try await withThrowingTaskGroup(of: (Int, DummyProductDataContainer?).self) { group in
            // We need to do at least one fetch to get the total
            let firstFetch = try await fetchDummyProducts(limit: Constants.DummyProductsAPIPageSize, skip: 0)
            let (firstPage, _) = firstFetch

            // Build params for the next paginated fetches and then add a task for each fetch into the group.
            let paginatedParams = APIServiceImpl.buildParamsForThePagesToFetch(
                pageSize: Constants.DummyProductsAPIPageSize,
                totalFetched: firstPage.skip + firstPage.limit,
                total: firstPage.total
            )

            // We also want to maintain the order of the results so we're going to use one array and save the fetched page by index.
            var paginatedPages: [DummyProductDataContainer?] = Array(repeating: nil, count: paginatedParams.count + 1)

            // Add the parallel tasks to the group
            for (index, paginatedParam) in paginatedParams.enumerated() {
                group.addTask {
                    return (index, try await fetchDummyProducts(limit: paginatedParam.limit, skip: paginatedParam.skip).0)
                }
            }
            
            // Wait for them and store them in the paginatedPages by index
            for try await (index, paginatedPage) in group {
                paginatedPages[index] = paginatedPage
            }

            let fetchedPages = paginatedPages.compactMap({ $0 })
            let productsFromFetchedPages = fetchedPages.flatMap({ $0.products })

            let dataContainter = DummyProductDataContainer(
                total: firstPage.total,
                skip: firstPage.skip,
                limit: firstPage.limit,
                products: firstPage.products + productsFromFetchedPages
            )
            return (dataContainter, .remote)
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
    static func buildParamsForThePagesToFetch(pageSize: Int, totalFetched: Int, total: Int) -> [(limit: Int, skip: Int)] {
        var acum: [(limit: Int, skip: Int)] = []

        var numberOfFetchedElements = totalFetched
        var hasMorePages = numberOfFetchedElements < total

        while hasMorePages {
            acum.append((limit: pageSize, skip: numberOfFetchedElements))
            numberOfFetchedElements += pageSize
            hasMorePages = numberOfFetchedElements < total
        }

        return acum
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
