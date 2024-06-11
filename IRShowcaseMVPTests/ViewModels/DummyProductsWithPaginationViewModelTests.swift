//
//  DummyProductsWithPaginationViewModelTests.swift
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

final class DummyProductsWithPaginationViewModelTests: TestCase {
    private var subject: DummyProductsWithPaginationViewModelImpl!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    func testShouldFetchRemoteDataIfDataIsntAvailableLocally() {
        let expectation = self.expectation(description: "Expected to testShouldFetchRemoteDataIfDataIsntAvailableLocally")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let localDataProviderMock = DummyProductsFetchAndSaveDataProviderMock()
        let remoteDataProviderMock = FetchDummyProductsProtocolMock()
        subject = DummyProductsWithPaginationViewModelImpl(
            routing: routingMock,
            localDataProvider: localDataProviderMock,
            remoteDataProvider: remoteDataProviderMock, 
            paginationSize: 10
        )

        Given(
            localDataProviderMock,
            .fetchDummyProducts(limit: .any, skip: .any, willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((.stub(), .local))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProducts(limit: .any, skip: .any, willProduce: { stubber in
                let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((dataContainer, .remote))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        subject.onAppear()

        subject
            .observableObject
            .$dummyProducts
            .dropFirst()
            .sink { array in
                XCTAssert(array.count > 0)

                remoteDataProviderMock.verify(.fetchDummyProductsAll(), count: .exactly(0))
                remoteDataProviderMock.verify(.fetchDummyProducts(limit: .any, skip: .any), count: .moreOrEqual(to: 1))
                localDataProviderMock.verify(.persistObjects(Parameter<DummyProductDataContainer>.any, saveCompletion: .any), count: .exactly(1))

                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testShouldntFetchRemotelyIfDataIsAvailableLocally() {
        let expectation = self.expectation(description: "Expected to testShouldntFetchRemotelyIfDataIsAvailableLocally")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let localDataProviderMock = DummyProductsFetchAndSaveDataProviderMock()
        let remoteDataProviderMock = FetchDummyProductsProtocolMock()
        subject = DummyProductsWithPaginationViewModelImpl(
            routing: routingMock,
            localDataProvider: localDataProviderMock,
            remoteDataProvider: remoteDataProviderMock, 
            paginationSize: 10
        )

        Given(
            localDataProviderMock,
            .fetchDummyProducts(limit: .any, skip: .any, willProduce: { stubber in
                let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((dataContainer, .local))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProductsAll(willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((.stub(), .remote))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        subject.onAppear()

        subject
            .observableObject
            .$dummyProducts
            .dropFirst()
            .sink { array in
                XCTAssert(array.count > 0)

                remoteDataProviderMock.verify(.fetchDummyProducts(limit: .any, skip: .any), count: .exactly(0))
                localDataProviderMock.verify(.persistObjects(Parameter<DummyProductDataContainer>.any, saveCompletion: .any), count: .exactly(0))
                
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testShowErrorIfItCouldntFetchLocallyOrRemote() {
        let expectation = self.expectation(description: "Expected to showErrorIfItCouldntFetchLocallyOrRemote")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let localDataProviderMock = DummyProductsFetchAndSaveDataProviderMock()
        let remoteDataProviderMock = FetchDummyProductsProtocolMock()
        subject = DummyProductsWithPaginationViewModelImpl(
            routing: routingMock,
            localDataProvider: localDataProviderMock,
            remoteDataProvider: remoteDataProviderMock, 
            paginationSize: 10
        )

        Given(
            localDataProviderMock,
            .fetchDummyProducts(limit: .any, skip: .any, willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((.stub(), .local))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProducts(limit: .any, skip: .any, willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((.stub(), .remote))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        subject.onAppear()

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
    }

    func testShouldntFetchNextPageWhenWeHaveTheWholeList() {
        let expectation = self.expectation(description: "Expected to shouldntFetchNextPageWhenWeHaveTheWholeList")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let localDataProviderMock = DummyProductsFetchAndSaveDataProviderMock()
        let remoteDataProviderMock = FetchDummyProductsProtocolMock()
        subject = DummyProductsWithPaginationViewModelImpl(
            routing: routingMock,
            localDataProvider: localDataProviderMock,
            remoteDataProvider: remoteDataProviderMock,
            paginationSize: 10
        )

        let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))

        Given(
            localDataProviderMock,
            .fetchDummyProducts(limit: .any, skip: .any, willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((dataContainer, .local))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProducts(limit: .any, skip: .any, willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((.stub(), .remote))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

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
                localDataProviderMock.verify(.fetchDummyProducts(limit: .any, skip: .any), count: .exactly(1))
                remoteDataProviderMock.verify(.fetchDummyProducts(limit: .any, skip: .any), count: .exactly(0))
                XCTAssertTrue(self.subject.observableObject.pagingState == .noMorePagesToLoad)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        subject.onAppear()
    }

    func testShouldFetchNextPageWhenItemIsCloseToTheThreshold() {
        let expectation = self.expectation(description: "Expected to shouldFetchNextPageWhenItemIsCloseToTheThreshold")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let localDataProviderMock = DummyProductsFetchAndSaveDataProviderMock()
        let remoteDataProviderMock = FetchDummyProductsProtocolMock()
        subject = DummyProductsWithPaginationViewModelImpl(
            routing: routingMock,
            localDataProvider: localDataProviderMock,
            remoteDataProvider: remoteDataProviderMock,
            paginationSize: 10
        )

        let dataContainerFromLocalJson: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
        let dataContainer: DummyProductDataContainer = .init(
            total: dataContainerFromLocalJson.total + 123,
            skip: dataContainerFromLocalJson.skip,
            limit: dataContainerFromLocalJson.limit,
            products: dataContainerFromLocalJson.products
        )

        Given(
            localDataProviderMock,
            .fetchDummyProducts(limit: .any, skip: .any, willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((dataContainer, .local))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProducts(limit: .any, skip: .any, willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((.stub(), .remote))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

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
                localDataProviderMock.verify(.fetchDummyProducts(limit: .any, skip: .any), count: .exactly(2))
                remoteDataProviderMock.verify(.fetchDummyProducts(limit: .any, skip: .any), count: .exactly(0))
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
