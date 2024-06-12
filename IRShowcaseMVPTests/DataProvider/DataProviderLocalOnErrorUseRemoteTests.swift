//
//  DataProviderLocalOnErrorUseRemoteTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Quick
import Nimble
import SwiftyMocky
import Combine

@testable import IRShowcaseMVP

class DataProviderLocalOnErrorRemoteTests: QuickSpec {
    override class func spec() {
        describe("DataProvidersTests") {
            var dataProvider: DataProvider<DummyProductDataContainer>!
            let network = APIServiceMock()
            let persistence = PersistenceLayerMock()
            var cancellables: Set<AnyCancellable>!

            beforeEach {
                let dp: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
                    config: DataProviderConfiguration.localOnErrorUseRemote,
                    network: network,
                    persistence: persistence
                )
                dataProvider = dp
                cancellables = Set<AnyCancellable>()
            }

            afterEach {
                dataProvider = nil
                cancellables.removeAll()
            }

            describe("local and on error use remote data provider") {
                context("fetch stuff method") {
                    it("should get a success result on the happy path") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(.any, willReturn: {
                            let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
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

                        waitUntil(timeout: .seconds(5), action: { (done) in
                            dataProvider
                                .fetchStuff(resource: .dummyProductsAll)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.products.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should error if both layers returns an error and/or invalid data") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(.any, willReturn: {
                            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
                            publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "Error"))))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((NSData() as Data, URLResponse()))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(timeout: .seconds(5), action: { (done) in
                            dataProvider
                                .fetchStuff(resource: .dummyProductsAll)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        done()
                                    }
                                } receiveValue: { values in
                                    fail()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should get persisted posts even if parsing step after network fails") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(.any, willReturn: {
                            let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((NSData() as Data, URLResponse()))
                            publisher.send(completion: .failure(DataProviderError.fetch(error: NSError.error(withMessage: "Fetch error"))))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(timeout: .seconds(5), action: { (done) in
                            dataProvider
                                .fetchStuff(resource: .dummyProductsAll)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.products.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should get network posts if theres was an error on the persistence layer") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
                                publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "Error"))))
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
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

                        waitUntil(timeout: .seconds(5), action: { (done) in
                            dataProvider
                                .fetchStuff(resource: .dummyProductsAll)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.products.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should succeed if nothing (empty array) is returned from the persistence layer") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
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

                        waitUntil(timeout: .seconds(5), action: { (done) in
                            dataProvider
                                .fetchStuff(resource: .dummyProductsAll)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    let (value, source) = values

                                    switch source {
                                    case .local:
                                        expect(value.products.count).to(equal(0))
                                        done()
                                    case .remote:
                                        fail()
                                    }
                                }
                                .store(in: &cancellables)
                        })
                    }
                }
            }
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
