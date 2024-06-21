//
//  DataProviderRemoteOnErrorUseLocalTests.swift
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

@Suite(.tags(.dataProvider, .remoteOnErrorUseLocalDataProviderConfig))
final class DataProviderRemoteOnErrorUseLocalTests {
    let network = APIServiceMock()
    let persistence = PersistenceLayerMock()
    let dpConfig = DataProviderConfiguration.remoteOnErrorUseLocal
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
        }()))

        Given(
            persistence,
            .fetchResourcePublisher(
                .any,
                willReturn: {
                    let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                    let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
                    return publisher.eraseToAnyPublisher()
                }()
            )
        )

        try await confirmation(expectedCount: 1) { confirmation in
            dataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    confirmation()
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        Issue.record("Shouldnt fail here")
                    }
                } receiveValue: { values in
                    let (value, source) = values

                    switch source {
                    case .local:
                        Issue.record("Shouldnt hit the local layer")
                    case .remote:
                        #expect(value.products.count > 0)
                    }

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

        let values = try await dataProvider.fetchStuff(resource: .dummyProductsAll)
        #expect(values.count == 1)
        #expect(values.first!.1 == .remote)
        #expect(values.first!.0.products.count > 0)
    }

    @Test(.tags(.fetchStuffPublisher))
    func shouldErrorIfBothLayersReturnsErrorOrInvalidDataPublisher() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(network, .fetchDataPublisher( request: .any, willReturn: {
            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((NSData() as Data, URLResponse()))
            return publisher.eraseToAnyPublisher()
        }()))

        Given(
            persistence,
            .fetchResourcePublisher(
                .any,
                willProduce: { stubber in
                    let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
                    publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "Error"))))
                    stubber.return(publisher.eraseToAnyPublisher())
                }
            )
        )

        try await confirmation(expectedCount: 2) { confirmation in
            dataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    confirmation()
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        confirmation()
                    }
                } receiveValue: { values in
                    Issue.record("Shouldnt receive a value")
                }
                .store(in: &cancellables)

            let duration = UInt64(0.3 * 1_000_000_000)
            try await Task.sleep(nanoseconds: duration)
        }
    }

    @Test(.tags(.fetchStuff))
    func shouldErrorIfBothLayersReturnsErrorOrInvalidData() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(network, .fetchData( request: .any, willReturn: {
            return (NSData() as Data, URLResponse())
        }()))

        Given(
            persistence,
            .fetchResource(
                .any,
                willThrow: PersistenceLayerError.persistence(error: NSError.error(withMessage: "Error"))
            )
        )

        await #expect(throws: DataProviderError.self) {
            try await dataProvider.fetchStuff(resource: .dummyProductsAll)
        }
    }

    @Test(.tags(.fetchStuffPublisher))
    func shouldGetPersistedValuesEvenIfParsingStepOnTheNetworkFailsPublisher() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(network, .fetchDataPublisher( request: .any, willReturn: {
            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((NSData() as Data, URLResponse()))
            publisher.send(completion: .failure(DataProviderError.fetch(error: NSError.error(withMessage: "Fetch error"))))
            return publisher.eraseToAnyPublisher()
        }()))

        Given(
            persistence,
            .fetchResourcePublisher(
                .any,
                willReturn: {
                    let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                    let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
                    return publisher.eraseToAnyPublisher()
                }()
            )
        )

        try await confirmation(expectedCount: 1) { confirmation in
            dataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    confirmation()
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
    func shouldGetPersistedValuesEvenIfParsingStepOnTheNetworkFails() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(network, .fetchData( request: .any, willReturn: {
            return (NSData() as Data, URLResponse())
        }()))

        Given(
            persistence,
            .fetchResource(
                .any,
                willReturn: {
                    let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                    return dataContainer
                }()
            )
        )

        let values = try await dataProvider.fetchStuff(resource: .dummyProductsAll)
        #expect(values.count > 0)
    }

    @Test(.tags(.fetchStuffPublisher))
    func shouldGetNetworkValuesIfTheresAnErrorInThePersistenceLayerPublisher() async throws {
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
        }()))

        Given(
            persistence,
            .fetchResourcePublisher(
                .any,
                willReturn: {
                    let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                    let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
                    publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "Persistence error"))))
                    return publisher.eraseToAnyPublisher()
                }()
            )
        )

        try await confirmation(expectedCount: 1) { confirmation in
            dataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    confirmation()
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
    func shouldGetNetworkValuesIfTheresAnErrorInThePersistenceLayer() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(network, .fetchData( request: .any, willReturn: {
            let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
            var data: Data? = nil
            do {
                let jsonData = try JSONEncoder().encode(dataContainer)
                data = jsonData
            } catch { }

            if let d = data {
                return (d, URLResponse())
            } else {
                return (NSData() as Data, URLResponse())
            }
        }()))

        Given(
            persistence,
            .fetchResource(
                .any,
                willThrow: PersistenceLayerError.persistence(error: NSError.error(withMessage: "Persistence error"))
            )
        )

        let values = try await dataProvider.fetchStuff(resource: .dummyProductsAll)
        #expect(values.count > 0)
    }

    @Test(.tags(.fetchStuffPublisher))
    func shouldReceiveValuesFromBothLayersEvenIfEmptyArrayIsReturnedFromThePersistencePublisher() async throws {
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
        }()))

        Given(
            persistence,
            .fetchResourcePublisher(
                .any,
                willReturn: {
                    let dataContainer = DummyProductDataContainer(total: 0, skip: 0, limit: 0, products: [])
                    let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
                    return publisher.eraseToAnyPublisher()
                }()
            )
        )

        try await confirmation(expectedCount: 1) { confirmation in
            dataProvider.fetchStuffPublisher(resource: .dummyProductsAll)
                .sink { completion in
                    confirmation()
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        Issue.record("Shouldnt receive a failure")
                    }
                } receiveValue: { values in
                    let (value, source) = values

                    switch source {
                    case .local:
                        Issue.record("Shouldnt receive a local value. Should only fetch locally on error from the remote layer.")
                    case .remote:
                        #expect(value.products.count > 0)
                        break
                    }

                    confirmation()
                }
                .store(in: &cancellables)

            let duration = UInt64(0.3 * 1_000_000_000)
            try await Task.sleep(nanoseconds: duration)
        }
    }

    @Test(.tags(.fetchStuff))
    func shouldReceiveValuesFromBothLayersEvenIfEmptyArrayIsReturnedFromThePersistence() async throws {
        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(network, .fetchData( request: .any, willReturn: {
            let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
            var data: Data? = nil
            do {
                let jsonData = try JSONEncoder().encode(dataContainer)
                data = jsonData
            } catch { }

            if let d = data {
                return (d, URLResponse())
            } else {
                return (NSData() as Data, URLResponse())
            }
        }()))

        Given(
            persistence,
            .fetchResource(
                .any,
                willReturn: {
                    let dataContainer = DummyProductDataContainer(total: 0, skip: 0, limit: 0, products: [])
                    return dataContainer
                }()
            )
        )

        let values = try await dataProvider.fetchStuff(resource: .dummyProductsAll)
        #expect(values.count == 1)
        #expect(values.first!.1 == .remote)
        #expect(values.first!.0.products.count > 0)
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
