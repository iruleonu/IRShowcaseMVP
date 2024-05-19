//
//  DummyProductsListViewModelTests.swift
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

final class DummyProductsListViewModelTests: TestCase {
    private var subject: DummyProductsViewModelImpl!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    func testShouldFetchRemoteDataIfDataIsntAvailableLocally() {
        let expectation = self.expectation(description: "Expected to testShouldFetchRemoteDataIfDataIsntAvailableLocally")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let localDataProviderMock = DummyProductsLocalDataProviderMock()
        let remoteDataProviderMock = FetchDummyProductsProtocolMock()
        subject = DummyProductsViewModelImpl(
            routing: routingMock,
            localDataProvider: localDataProviderMock,
            remoteDataProvider: remoteDataProviderMock
        )

        Given(
            localDataProviderMock,
            .fetchDummyProductsAll(willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((.stub(), .local))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProductsAll(willProduce: { stubber in
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

                remoteDataProviderMock.verify(.fetchDummyProductsAll(), count: .moreOrEqual(to: 1))
                localDataProviderMock.verify(.persistObjects(Parameter<DummyProductDataContainer>.any, saveCompletion: .any), count: .exactly(1))

                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testShouldntFetchRemotelyIfDataIsAvailableLocally() {
        let expectation = self.expectation(description: "Expected to testShouldntFetchRemotelyIfDataIsAvailableLocally")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let routingMock = DummyProductsScreenRoutingMock()
        let localDataProviderMock = DummyProductsLocalDataProviderMock()
        let remoteDataProviderMock = FetchDummyProductsProtocolMock()
        subject = DummyProductsViewModelImpl(
            routing: routingMock,
            localDataProvider: localDataProviderMock,
            remoteDataProvider: remoteDataProviderMock
        )

        Given(
            localDataProviderMock,
            .fetchDummyProductsAll(willProduce: { stubber in
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
        let localDataProviderMock = DummyProductsLocalDataProviderMock()
        let remoteDataProviderMock = FetchDummyProductsProtocolMock()
        subject = DummyProductsViewModelImpl(
            routing: routingMock,
            localDataProvider: localDataProviderMock,
            remoteDataProvider: remoteDataProviderMock
        )

        Given(
            localDataProviderMock,
            .fetchDummyProductsAll(willProduce: { stubber in
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((.stub(), .local))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProductsAll(willProduce: { stubber in
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
