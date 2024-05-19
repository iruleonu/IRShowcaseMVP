//
//  DummyProductsWithHybridDataProviderViewModelTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 17/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//


import Foundation
import XCTest
import SwiftUI
import SwiftyMocky
import Combine

@testable import IRShowcaseMVP

final class DummyProductsWithHybridDataProviderViewModelTests: TestCase {
    private var subject: DummyProductsWithHybridDataProviderViewModelImpl!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    func testShouldFetchRemoteDataIfDataIsntAvailableLocally() {
        let expectation = self.expectation(description: "Expected to ShouldFetchRemoteDataIfDataIsntAvailableLocally")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let networkMock = APIServiceMock()
        let persistenceMock = PersistenceLayerMock()
        let dataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: DataProviderConfiguration.localOnErrorUseRemote,
            network: networkMock,
            persistence: persistenceMock
        )
        subject = DummyProductsWithHybridDataProviderViewModelImpl(
            routing: routingMock,
            dataProvider: dataProvider
        )

        Given(persistenceMock, .fetchResource(.any, willReturn: {
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
            publisher.send(completion: .failure(PersistenceLayerError.emptyResult(error: DataProviderError.casting)))
            return publisher.eraseToAnyPublisher()
        }()
        ))

        Given(networkMock, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(networkMock, .fetchData( request: .any, willReturn: {
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

        subject
            .observableObject
            .$showErrorView
            .sink { showErrorView in
                XCTAssertFalse(showErrorView)
            }
            .store(in: &cancellables)

        subject
            .observableObject
            .$dummyProducts
            .dropFirst()
            .sink { array in
                XCTAssert(array.count > 0)

                persistenceMock.verify(.fetchResource(.any), count: .exactly(1))
                networkMock.verify(.fetchData(request: .any), count: .exactly(1))
                persistenceMock.verify(.persistObjects(Parameter<DummyProductDataContainer>.any, saveCompletion: .any), count: .exactly(1))

                expectation.fulfill()
            }
            .store(in: &cancellables)

        subject.onAppear()
    }

    func testShouldntFetchRemotelyIfDataIsAvailableLocally() {
        let expectation = self.expectation(description: "Expected to ShouldntFetchRemotelyIfDataIsAvailableLocally")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let networkMock = APIServiceMock()
        let persistenceMock = PersistenceLayerMock()
        let dataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: DataProviderConfiguration.localOnErrorUseRemote,
            network: networkMock,
            persistence: persistenceMock
        )
        subject = DummyProductsWithHybridDataProviderViewModelImpl(
            routing: routingMock,
            dataProvider: dataProvider
        )

        Given(persistenceMock, .fetchResource(.any, willReturn: {
            let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
            return publisher.eraseToAnyPublisher()
        }()
        ))

        Given(networkMock, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(networkMock, .fetchData( request: .any, willReturn: {
            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))
            publisher.send(completion: .failure(DataProviderError.noConnectivity))
            return publisher.eraseToAnyPublisher()
        }()
        ))

        subject
            .observableObject
            .$showErrorView
            .sink { showErrorView in
                XCTAssertFalse(showErrorView)
            }
            .store(in: &cancellables)

        subject
            .observableObject
            .$dummyProducts
            .dropFirst()
            .sink { array in
                XCTAssert(array.count > 0)

                persistenceMock.verify(.fetchResource(.any), count: .exactly(1))
                networkMock.verify(.fetchData(request: .any), count: .exactly(0))
                persistenceMock.verify(.persistObjects(Parameter<DummyProductDataContainer>.any, saveCompletion: .any), count: .exactly(0))

                expectation.fulfill()
            }
            .store(in: &cancellables)

        subject.onAppear()
    }

    func testShowErrorIfItCouldntFetchLocallyOrRemote() {
        let expectation = self.expectation(description: "Expected to ShowErrorIfItCouldntFetchLocallyOrRemote")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let networkMock = APIServiceMock()
        let persistenceMock = PersistenceLayerMock()
        let dataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: DataProviderConfiguration.localOnErrorUseRemote,
            network: networkMock,
            persistence: persistenceMock
        )
        subject = DummyProductsWithHybridDataProviderViewModelImpl(
            routing: routingMock,
            dataProvider: dataProvider
        )

        Given(persistenceMock, .fetchResource(.any, willReturn: {
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
            publisher.send(completion: .failure(PersistenceLayerError.emptyResult(error: DataProviderError.casting)))
            return publisher.eraseToAnyPublisher()
        }()
        ))

        Given(networkMock, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(networkMock, .fetchData( request: .any, willReturn: {
            let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))
            publisher.send(completion: .failure(DataProviderError.noConnectivity))
            return publisher.eraseToAnyPublisher()
        }()
        ))

        subject
            .observableObject
            .$showErrorView
            .filter({ $0 })
            .first()
            .sink { showErrorView in
                expectation.fulfill()
            }
            .store(in: &cancellables)

        subject.onAppear()
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
