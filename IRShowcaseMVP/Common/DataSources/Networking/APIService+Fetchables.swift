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
    func fetchBabyNamePopularities() -> AnyPublisher<BabyNamePopularityDataContainer, Error> {
        let urlRequest = Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: apiBaseUrl)
        
        func parseData(_ tuple: (Data, URLResponse)) throws -> BabyNamePopularityDataContainer {
            do {
                let (data, _) = tuple
                let result = try JSONDecoder().decode(BabyNamePopularityDataContainer.self, from: data)
                return result
            } catch {
                throw APIServiceError.parsing(error: error)
            }
        }
        
        return fetchData(urlRequest)
            .tryMap(parseData)
            .eraseToAnyPublisher()
    }
}

extension APIServiceImpl: FetchDummyProductsProtocol {
    func fetchDummyProducts(limit: Int, skip: Int) -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
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

        return fetchData(urlRequest)
            .tryMap(parseData)
            .map({ ($0, .remote) })
            .eraseToAnyPublisher()
    }

    func fetchDummyProductsAll() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        fetchDummyProductsAllPaginated()
    }
}

private extension APIServiceImpl {
    func fetchDummyProductsAllPaginated() -> AnyPublisher<(DummyProductDataContainer, DataProviderSource), Error> {
        let skipNumberApiQueryParamPublisher = CurrentValueSubject<Int, Never>(0)
        return skipNumberApiQueryParamPublisher
            .flatMap({ pageIndex in
                self.fetchDummyProducts(limit: Constants.DummyProductsAPIPageSize, skip: pageIndex).eraseToAnyPublisher()
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
