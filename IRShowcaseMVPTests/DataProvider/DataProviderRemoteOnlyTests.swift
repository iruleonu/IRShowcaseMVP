//
//  DataProviderRemoteOnlyTests.swift
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

class DataProviderRemoteOnlyTests: QuickSpec {
    override class func spec() {
        describe("DataProvidersTests") {
            var remoteDataProvider: DataProvider<DummyProductDataContainer>!
            let network = APIServiceMock()
            let persistence = PersistenceLayerMock()
            var cancellables: Set<AnyCancellable>!

            beforeEach {
                let remoteConfig = DataProviderConfiguration.remoteOnly
                let rdp: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(config: remoteConfig, network: network, persistence: persistence)
                remoteDataProvider = rdp
                cancellables = Set<AnyCancellable>()
            }

            afterEach {
                remoteDataProvider = nil
                cancellables.removeAll()
            }

            describe("remote data provider") {
                context("fetch stuff method") {
                    it("should get a success result on the happy path") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

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
                            remoteDataProvider
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

                    it("should fail before the parsing step when receives generic/empty data") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(network, .fetchData( request: .any, willReturn: {
                            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))
                            publisher.send((NSData() as Data, URLResponse()))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(timeout: .seconds(5), action: { (done) in
                            remoteDataProvider
                                .fetchStuff(resource: .dummyProductsAll)
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
        }
    }
}
