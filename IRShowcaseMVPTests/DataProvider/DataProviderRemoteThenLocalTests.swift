//
//  DataProviderRemoteThenLocalTests.swift
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

class DataProviderRemoteThenLocalTests: QuickSpec {
    override class func spec() {
        describe("DataProvidersTests") {
            var dataProvider: DataProvider<BabyNamePopularityDataContainer>!
            let network = APIServiceMock()
            let persistence = PersistenceLayerMock()
            var cancellables: Set<AnyCancellable>!

            beforeEach {
                let dp: DataProvider<BabyNamePopularityDataContainer> = DataProviderBuilder.makeDataProvider(
                    config: DataProviderConfiguration.remoteFirstThenLocal,
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

            describe("remote first then local data provider") {
                context("fetch stuff method") {
                    it("should get a success result (value) from both layers on the happy path") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
                        
                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
                                let publisher = CurrentValueSubject<BabyNamePopularityDataContainer, PersistenceLayerError>(babyNamePopularities)
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
                            var data: Data? = nil
                            do {
                                let jsonData = try JSONEncoder().encode(babyNamePopularities)
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

                        waitUntil(action: { (done) in
                            var invocationsCount = 0

                            dataProvider
                                .fetchStuff(resource: .babyNamePopularities)
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
                                        expect(value.babyNamePopularityRepresentation.count).to(beGreaterThan(0))
                                    case .remote:
                                        expect(value.babyNamePopularityRepresentation.count).to(beGreaterThan(0))
                                    }

                                    invocationsCount += 1;
                                    if (invocationsCount == 2) {
                                        done()
                                    }
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should error if both layers returns an error and/or invalid data") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let publisher = CurrentValueSubject<BabyNamePopularityDataContainer, PersistenceLayerError>(.init(data: []))
                                publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "Error"))))
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((NSData() as Data, URLResponse()))
                            publisher.send(completion: .failure(DataProviderError.fetch(error: NSError.error(withMessage: "Fetch error"))))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(action: { (done) in
                            dataProvider
                                .fetchStuff(resource: .babyNamePopularities)
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
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
                                let publisher = CurrentValueSubject<BabyNamePopularityDataContainer, PersistenceLayerError>(babyNamePopularities)
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((NSData() as Data, URLResponse()))
                            publisher.send(completion: .failure(DataProviderError.fetch(error: NSError.error(withMessage: "Fetch error"))))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(action: { (done) in
                            dataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.babyNamePopularityRepresentation.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should get network posts if theres was an error on the persistence layer") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let publisher = CurrentValueSubject<BabyNamePopularityDataContainer, PersistenceLayerError>(.init(data: []))
                                publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "Error"))))
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
                            var data: Data? = nil
                            do {
                                let jsonData = try JSONEncoder().encode(babyNamePopularities)
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

                        waitUntil(action: { (done) in
                            dataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.babyNamePopularityRepresentation.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should receive values from both layers even if nothing (empty array) is returned from the persistence layer") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let publisher = CurrentValueSubject<BabyNamePopularityDataContainer, PersistenceLayerError>(.init(data: []))
                                publisher.send(.init(data: []))
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
                            var data: Data? = nil
                            do {
                                let jsonData = try JSONEncoder().encode(babyNamePopularities)
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

                        waitUntil(action: { (done) in
                            var invocationsCount = 0;
                            
                            dataProvider
                                .fetchStuff(resource: .babyNamePopularities)
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
                                        expect(value.babyNamePopularityRepresentation.count).to(equal(0))
                                    case .remote:
                                        expect(value.babyNamePopularityRepresentation.count).to(beGreaterThan(0))
                                    }

                                    invocationsCount += 1;
                                    if (invocationsCount == 2) {
                                        done()
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
