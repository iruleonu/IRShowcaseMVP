//
//  DataProviderRemoteOnlyTests.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 21/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Testing
import Foundation
import Combine
import SwiftyMocky

@testable import IRShowcaseMVP

@Suite(.tags(.dataProvider, .remoteDataProviderConfig))
final class DataProviderRemoteOnlyTests {
    let network = APIServiceMock()
    let persistence = PersistenceLayerMock()
    let dpConfig = DataProviderConfiguration.remoteOnly
    let dataProvider: DataProvider<DummyProductDataContainer>
    var cancellables: Set<AnyCancellable>

    init() async throws {
        dataProvider = DataProviderBuilder.makeDataProvider(config: dpConfig, network: network, persistence: persistence)
        cancellables = Set<AnyCancellable>()
    }

    deinit {
        cancellables.removeAll()
    }

    @Test(.tags(.fetchStuffPublisher))
    func shouldGetASuccessResultOnTheHappyPathPublisher() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

        Given(network, .fetchDataPublisher( request: .any, willReturn: {
            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

            let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
            var data: Data? = nil
            do {
                let jsonData = try JSONEncoder().encode(dataContainer)
                data = jsonData
            } catch { }

            if let d = data {
                publisher.send((d, URLResponse()))
            } else {
                publisher.send(completion: .failure(DataProviderError.parsing(error: DataProviderError.unknown)))
            }

            return publisher.eraseToAnyPublisher()
        }()
        ))

        try await confirmation(expectedCount: 1) { confirmation in
            dataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        Issue.record("Shouldnt receive a failure")
                    }
                } receiveValue: { values in
                    #expect(values.0.products.count > 0)
                    confirmation()
                }
                .store(in: &cancellables)

            let duration = UInt64(0.3 * 1_000_000_000)
            try await Task.sleep(nanoseconds: duration)
        }
    }

    @Test(.tags(.fetchStuff))
    func shouldGetASuccessResultOnTheHappyPath() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(
            network,
            .fetchData(
                request: .any,
                willProduce: { stubber in
                    let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                    var data: Data? = nil
                    do {
                        let jsonData = try JSONEncoder().encode(dataContainer)
                        data = jsonData
                    } catch { }

                    if let d = data {
                        stubber.return((d, URLResponse()))
                    } else {
                        stubber.throw(DataProviderError.parsing(error: DataProviderError.unknown))
                    }
                }
            )
        )

        let values = try await dataProvider.fetchStuff(resource: .dummyProductsAll)
        #expect(values.count > 0)
    }

    @Test(.tags(.fetchStuffPublisher))
    func shouldFailBeforeTheParsingStepWhenReceivesEmptyDataPublisher() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

        Given(network, .fetchDataPublisher( request: .any, willReturn: {
            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))
            publisher.send((NSData() as Data, URLResponse()))
            return publisher.eraseToAnyPublisher()
        }()
        ))

        try await confirmation(expectedCount: 1) { confirmation in
            dataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        #expect(error.errorDescription == DataProviderError.parsing(error: DataProviderError.unknown).errorDescription)
                        confirmation()
                    }
                } receiveValue: { values in
                    Issue.record("Shouldnt receive a value with invalid data")
                }
                .store(in: &cancellables)

            let duration = UInt64(0.3 * 1_000_000_000)
            try await Task.sleep(nanoseconds: duration)
        }
    }

    @Test(.tags(.fetchStuff))
    func shouldFailBeforeTheParsingStepWhenReceivesEmptyData() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(
            network,
            .fetchData(
                request: .any,
                willProduce: { stubber in
                    stubber.return((NSData() as Data, URLResponse()))
                }
            )
        )

        await #expect(throws: DataProviderError.self) {
            try await dataProvider.fetchStuff(resource: .dummyProductsAll)
        }
    }
}
