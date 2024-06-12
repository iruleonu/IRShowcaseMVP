//
//  DataProviderLocalOnlyTests.swift
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

class DataProviderLocalOnlyTests: QuickSpec {
    override class func spec() {
        describe("DataProvidersTests") {
            var localDataProvider: DataProvider<DummyProductDataContainer>!
            let network = APIServiceMock()
            let persistence = PersistenceLayerMock()
            var cancellables: Set<AnyCancellable>!

            beforeEach {
                let localConfig = DataProviderConfiguration.localOnly
                let ldp: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(config: localConfig, network: network, persistence: persistence)
                localDataProvider = ldp
                cancellables = Set<AnyCancellable>()
            }

            afterEach {
                localDataProvider = nil
                cancellables.removeAll()
            }

            describe("local data provider") {
                context("fetch stuff method") {
                    it("should get a success result on the happy path") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(.any, willReturn: {
                            let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(timeout: .seconds(5), action: { (done) in
                            localDataProvider
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

                    it("should get a response after persistence error") {
                        Given(network, .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))

                        Given(persistence, .fetchResource(.any, willReturn: {
                            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
                            publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "No known resource"))))
                            return publisher.eraseToAnyPublisher()
                        }()
                        ))

                        waitUntil(timeout: .seconds(5), action: { (done) in
                            localDataProvider
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
