//
//  DummyProductsWithPaginationAndHybridDataProviderViewModelTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import XCTest
import SwiftUI
import SwiftyMocky
import Combine

@testable import IRShowcaseMVP

final class DummyProductsWithPaginationAndHybridDataProviderViewModelTests: TestCase {
    private var subject: DummyProductsWithPaginationAndHybridDataProviderViewModelImpl!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    @MainActor
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
        subject = DummyProductsWithPaginationAndHybridDataProviderViewModelImpl(
            routing: routingMock,
            dataProvider: dataProvider, 
            paginationSize: 10
        )

        Given(persistenceMock, .fetchResourcePublisher(.any, willReturn: {
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
            publisher.send(completion: .failure(PersistenceLayerError.emptyResult(error: DataProviderError.casting)))
            return publisher.eraseToAnyPublisher()
        }()
        ))

        Given(networkMock, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(networkMock, .fetchDataPublisher(request: .any, willReturn: {
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

                persistenceMock.verify(.fetchResourcePublisher(.any), count: .exactly(1))
                networkMock.verify(.fetchDataPublisher(request: .any), count: .exactly(1))
                persistenceMock.verify(.persistObjects(Parameter<DummyProductDataContainer>.any, saveCompletion: .any), count: .exactly(1))

                expectation.fulfill()
            }
            .store(in: &cancellables)

        subject.onAppear()
    }

    @MainActor
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
        subject = DummyProductsWithPaginationAndHybridDataProviderViewModelImpl(
            routing: routingMock,
            dataProvider: dataProvider, 
            paginationSize: 10
        )

        Given(persistenceMock, .fetchResourcePublisher(.any, willReturn: {
            let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
            return publisher.eraseToAnyPublisher()
        }()
        ))

        Given(networkMock, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(networkMock, .fetchDataPublisher( request: .any, willReturn: {
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

                persistenceMock.verify(.fetchResourcePublisher(.any), count: .exactly(1))
                networkMock.verify(.fetchDataPublisher(request: .any), count: .exactly(0))
                persistenceMock.verify(.persistObjects(Parameter<DummyProductDataContainer>.any, saveCompletion: .any), count: .exactly(0))

                expectation.fulfill()
            }
            .store(in: &cancellables)

        subject.onAppear()
    }

    @MainActor
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
        subject = DummyProductsWithPaginationAndHybridDataProviderViewModelImpl(
            routing: routingMock,
            dataProvider: dataProvider, 
            paginationSize: 10
        )

        Given(persistenceMock, .fetchResourcePublisher(.any, willReturn: {
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(.stub())
            publisher.send(completion: .failure(PersistenceLayerError.emptyResult(error: DataProviderError.casting)))
            return publisher.eraseToAnyPublisher()
        }()
        ))

        Given(networkMock, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(networkMock, .fetchDataPublisher( request: .any, willReturn: {
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

    @MainActor
    func testShouldntFetchNextPageWhenWeHaveTheWholeList() {
        let expectation = self.expectation(description: "Expected to shouldntFetchNextPageWhenWeHaveTheWholeList")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let networkMock = APIServiceMock()
        let persistenceMock = PersistenceLayerMock()
        let dataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: DataProviderConfiguration.localOnErrorUseRemote,
            network: networkMock,
            persistence: persistenceMock
        )
        subject = DummyProductsWithPaginationAndHybridDataProviderViewModelImpl(
            routing: routingMock,
            dataProvider: dataProvider,
            paginationSize: 10
        )

        let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))

        Given(persistenceMock, .fetchResourcePublisher(.any, willReturn: {
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
            return publisher.eraseToAnyPublisher()
        }()
        ))

        Given(networkMock, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(networkMock, .fetchDataPublisher(request: .any, willReturn: {
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
                XCTAssertTrue(showErrorView)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let onAppearPublisher = PassthroughSubject<Int, Never>()
        let onItemAppearPublisher = PassthroughSubject<Int, Never>()

        subject
            .observableObject
            .$dummyProducts
            .dropFirst()
            .first()
            .receive(on: DispatchQueue.main)
            .sink { array in
                XCTAssert(array.count > 0)
                onAppearPublisher.send(0)
                onAppearPublisher.send(completion: .finished)
                self.subject.onItemAppear(dataContainer.products.last!)
                onItemAppearPublisher.send(0)
                onItemAppearPublisher.send(completion: .finished)
            }
            .store(in: &cancellables)

        Publishers.Zip(onAppearPublisher, onItemAppearPublisher)
            .sink { value in
                persistenceMock.verify(.fetchResourcePublisher(.any), count: .exactly(1))
                networkMock.verify(.fetchDataPublisher(request: .any), count: .exactly(0))
                XCTAssertTrue(self.subject.observableObject.pagingState == .noMorePagesToLoad)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        subject.onAppear()
    }

    @MainActor
    func testShouldFetchNextPageWhenItemIsCloseToTheThreshold() {
        let expectation = self.expectation(description: "Expected to shouldFetchNextPageWhenItemIsCloseToTheThreshold")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let networkMock = APIServiceMock()
        let persistenceMock = PersistenceLayerMock()
        let dataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: DataProviderConfiguration.localOnErrorUseRemote,
            network: networkMock,
            persistence: persistenceMock
        )
        subject = DummyProductsWithPaginationAndHybridDataProviderViewModelImpl(
            routing: routingMock,
            dataProvider: dataProvider,
            paginationSize: 10
        )

        let dataContainerFromLocalJson: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
        let dataContainer: DummyProductDataContainer = .init(
            total: dataContainerFromLocalJson.total + 123,
            skip: dataContainerFromLocalJson.skip,
            limit: dataContainerFromLocalJson.limit,
            products: dataContainerFromLocalJson.products
        )

        Given(persistenceMock, .fetchResourcePublisher(.any, willReturn: {
            let publisher = CurrentValueSubject<DummyProductDataContainer, PersistenceLayerError>(dataContainer)
            return publisher.eraseToAnyPublisher()
        }()
        ))

        Given(networkMock, .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!)))
        Given(networkMock, .fetchDataPublisher(request: .any, willReturn: {
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
                XCTAssertTrue(showErrorView)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let onAppearPublisher = PassthroughSubject<Int, Never>()
        let onItemAppearPublisher = PassthroughSubject<Int, Never>()

        subject
            .observableObject
            .$dummyProducts
            .dropFirst()
            .first()
            .receive(on: DispatchQueue.main)
            .sink { array in
                XCTAssert(array.count > self.subject.thresholdToStartFetchingNextPage)
                onAppearPublisher.send(0)
                onAppearPublisher.send(completion: .finished)

                let itemAtIndex = dataContainer.products[dataContainer.products.count - self.subject.thresholdToStartFetchingNextPage]
                self.subject.onItemAppear(itemAtIndex)
                onItemAppearPublisher.send(0)
                onItemAppearPublisher.send(completion: .finished)
            }
            .store(in: &cancellables)

        Publishers.Zip(onAppearPublisher, onItemAppearPublisher)
            .sink { value in
                persistenceMock.verify(.fetchResourcePublisher(.any), count: .exactly(2))
                networkMock.verify(.fetchDataPublisher(request: .any), count: .exactly(0))
                XCTAssertTrue(self.subject.observableObject.pagingState == .loadingNextPage || self.subject.observableObject.pagingState == .loaded)
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
