//
//  DataProviderLocalOnlyTests.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Testing
import Foundation
import Combine
import SwiftyMocky

@testable import IRShowcaseMVP

@Suite(.tags(.dataProvider, .localDataProviderConfig))
struct DataProviderLocalOnlyTests {
    let network = APIServiceMock()
    let persistence = PersistenceLayerMock()
    let dpConfig = DataProviderConfiguration.localOnly

    @Test(.tags(.fetchStuffPublisher), .tags(.fetchStuff))
    func shouldGetASuccessResultOnTheHappyPath() async throws {
        let localDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(config: dpConfig, network: network, persistence: persistence)
        var cancellables = Set<AnyCancellable>()

        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

        Given(
            persistence,
            .fetchResource(
                .any,
                willProduce: { stubber in
                    let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                    stubber.return(dataContainer)
                }
            )
        )
        Given(
            persistence,
            .fetchResourcePublisher(
                .any,
                willProduce: { stubber in
                    let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                    let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
                    stubber.return(publisher.eraseToAnyPublisher())
                }
            )
        )

        try await confirmation { confirmation in
            // Combine
            localDataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        #expect(false == false)
                    }
                } receiveValue: { values in
                    #expect(values.0.products.count > 0)
                    confirmation()
                }
                .store(in: &cancellables)

            let duration = UInt64(0.3 * 1_000_000_000)
            try await Task.sleep(nanoseconds: duration)
        }

        // Async
        let values = try await localDataProvider.fetchStuff(resource: .dummyProductsAll)
        #expect(values.count > 0)
    }

    @Test(.tags(.fetchStuffPublisher), .tags(.fetchStuff))
    func shouldGetAResponseAfterPersistenceError() async throws {
        let localDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(config: dpConfig, network: network, persistence: persistence)
        var cancellables = Set<AnyCancellable>()

        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

        Given(
            persistence,
            .fetchResource(
                .any,
                willThrow: PersistenceLayerError.persistence(error: NSError.error(withMessage: "No known resource"))
            )
        )

        Given(persistence, .fetchResourcePublisher(.any, willReturn: {
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
            publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "No known resource"))))
            return publisher.eraseToAnyPublisher()
        }()
        ))

        try await confirmation { confirmation in
            // Combine
            localDataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        confirmation()
                    }
                } receiveValue: { values in
                    #expect(false == true)
                }
                .store(in: &cancellables)

            let duration = UInt64(0.3 * 1_000_000_000)
            try await Task.sleep(nanoseconds: duration)
        }

        // Async
        await #expect(throws: DataProviderError.self) {
            try await localDataProvider.fetchStuff(resource: .dummyProductsAll)
        }
    }
}

private extension DummyProductDataContainer {
    static func stub() -> DummyProductDataContainer {
        .init(
            total: 0,
            skip: 0,
            limit: 0,
            products: []
        )
    }
}
