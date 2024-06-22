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

    @Test(.tags(.fetchStuffPublisher))
    func shouldGetASuccessResultOnTheHappyPathPublisher() async throws {
        let localDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(config: dpConfig, network: network, persistence: persistence)
        var cancellables = Set<AnyCancellable>()

        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

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

        await confirmation { confirmation in
            let sleepTask = TestsHelper.sleepTask()

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
                    sleepTask.cancel()
                }
                .store(in: &cancellables)

            await sleepTask.value
        }
    }

    @Test(.tags(.fetchStuff))
    func shouldGetASuccessResultOnTheHappyPath() async throws {
        let localDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(config: dpConfig, network: network, persistence: persistence)

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

        // Async
        let values = try await localDataProvider.fetchStuff(resource: .dummyProductsAll)
        #expect(values.count > 0)
    }

    @Test(.tags(.fetchStuffPublisher))
    func shouldGetAResponseAfterPersistenceErrorPublisher() async throws {
        let localDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(config: dpConfig, network: network, persistence: persistence)
        var cancellables = Set<AnyCancellable>()

        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

        Given(persistence, .fetchResourcePublisher(.any, willReturn: {
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
            publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "No known resource"))))
            return publisher.eraseToAnyPublisher()
        }()
        ))

        await confirmation { confirmation in
            let sleepTask = TestsHelper.sleepTask()

            localDataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        confirmation()
                        sleepTask.cancel()
                    }
                } receiveValue: { values in
                    #expect(false == true)
                }
                .store(in: &cancellables)

            await sleepTask.value
        }
    }

    @Test(.tags(.fetchStuff))
    func shouldGetAResponseAfterPersistenceError() async throws {
        let localDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(config: dpConfig, network: network, persistence: persistence)

        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

        Given(
            persistence,
            .fetchResource(
                .any,
                willThrow: PersistenceLayerError.persistence(error: NSError.error(withMessage: "No known resource"))
            )
        )

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
