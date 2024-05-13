//
//  DataProviderTests.swift
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

class DataProvidersTests: QuickSpec {
    override class func spec() {
        describe("DataProvidersTests") {
            var localDataProvider: DataProvider<[BabyNamePopularity]>!
            var remoteDataProvider: DataProvider<[BabyNamePopularity]>!
            var hybridLocalFirstDataProvider: DataProvider<[BabyNamePopularity]>!
            var hybridRemoteFirstDataProvider: DataProvider<[BabyNamePopularity]>!
            let network = APIServiceMock()
            let persistence = PersistenceLayerMock()
            var cancellables: Set<AnyCancellable>!

            beforeEach {
                let localConfig = DataProviderConfiguration.localOnly
                let remoteConfig = DataProviderConfiguration.remoteOnly
                let hybridLocalConfig = DataProviderConfiguration.localIfErrorUseRemote
                let hybridRemoteConfig = DataProviderConfiguration.remoteIfErrorUseLocal
                let ldp: DataProvider<[BabyNamePopularity]> = DataProviderBuilder.makeDataProvider(config: localConfig, network: network, persistence: persistence)
                let rdp: DataProvider<[BabyNamePopularity]> = DataProviderBuilder.makeDataProvider(config: remoteConfig, network: network, persistence: persistence)
                let hldp: DataProvider<[BabyNamePopularity]> = DataProviderBuilder.makeDataProvider(config: hybridLocalConfig, network: network, persistence: persistence)
                let hrdp: DataProvider<[BabyNamePopularity]> = DataProviderBuilder.makeDataProvider(config: hybridRemoteConfig, network: network, persistence: persistence)
                localDataProvider = ldp
                remoteDataProvider = rdp
                hybridLocalFirstDataProvider = hldp
                hybridRemoteFirstDataProvider = hrdp
                cancellables = Set<AnyCancellable>()
            }

            afterEach {
                localDataProvider = nil
                remoteDataProvider = nil
                hybridLocalFirstDataProvider = nil
                hybridRemoteFirstDataProvider = nil
                cancellables.removeAll()
            }

            describe("remote data provider") {
                context("fetch stuff method") {
                    it("should get a success result on the happy path") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
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
                            remoteDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should fail before the parsing step when receives generic/empty data") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))
                            publisher.send((NSData() as Data, URLResponse()))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(action: { (done) in
                            remoteDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure(let error):
                                        expect(error.errorDescription).to(equal(DataProviderError.parsing(error: DataProviderError.unknown).errorDescription))
                                        done()
                                    }
                                } receiveValue: { values in
                                    fail()
                                }
                                .store(in: &cancellables)
                        })
                    }
                }
            }

            describe("local data provider") {
                context("fetch stuff method") {
                    it("should get a success result on the happy path") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(.any, willReturn: {
                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
                            let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>(babyNamePopularities)
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(action: { (done) in
                            localDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should get a response after persistence error") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(.any, willReturn: {
                            let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>([])
                            publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "No known resource"))))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(action: { (done) in
                            localDataProvider
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
                }
            }

            describe("hybrid local first data provider") {
                context("fetch stuff method") {
                    it("should get a success result on the happy path") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
                        
                        Given(persistence, .fetchResource(.any, willReturn: {
                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
                            let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>(babyNamePopularities)
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
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
                            hybridLocalFirstDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should error if both layers returns an error and/or invalid data") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(.any, willReturn: {
                            let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>([])
                            publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "Error"))))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((NSData() as Data, URLResponse()))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(action: { (done) in
                            hybridLocalFirstDataProvider
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

                        Given(persistence, .fetchResource(.any, willReturn: {
                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
                            let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>(babyNamePopularities)
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
                            hybridLocalFirstDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(beGreaterThan(0))
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
                                let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>([])
                                publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "Error"))))
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
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
                            hybridLocalFirstDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should succeed if nothing is returned from the persistence layer") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>([])
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
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
                            hybridLocalFirstDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }
                }
            }

            describe("hybrid remote first data provider") {
                context("fetch stuff method") {
                    it("should get a success result on the happy path") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
                        
                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
                                let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>(babyNamePopularities)
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
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
                            hybridRemoteFirstDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should error if both layers returns an error and/or invalid data") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>([])
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
                            hybridRemoteFirstDataProvider
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
                                let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
                                let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>(babyNamePopularities)
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
                            hybridRemoteFirstDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(beGreaterThan(0))
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
                                let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>([])
                                publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "Error"))))
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
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
                            hybridRemoteFirstDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(beGreaterThan(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }

                    it("should succeed if nothing is returned from the persistence layer") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(
                            .any,
                            willReturn: {
                                let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>([])
                                publisher.send([])
                                return publisher.eraseToAnyPublisher()
                            }()
                        ))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))

                            let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
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
                            hybridRemoteFirstDataProvider
                                .fetchStuff(resource: .babyNamePopularities)
                                .sink { completion in
                                    switch completion {
                                    case .finished:
                                        break
                                    case .failure:
                                        fail()
                                    }
                                } receiveValue: { values in
                                    expect(values.0.count).to(equal(0))
                                    done()
                                }
                                .store(in: &cancellables)
                        })
                    }
                }
            }
        }
    }
}
