//
//  DummyProductsListViewPresenterTests.swift
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

final class DummyProductsListViewPresenterTests: TestCase {
    private var subject: DummyProductsViewModelImpl!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    func testShouldFetchRemoteDataIfDataIsntAvailableLocally() {
        let expectation = self.expectation(description: "Expected to get data on success response")
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
            .fetchDummyProducts(willProduce: { stubber in
                let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((dataContainer, .local))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProducts(willProduce: { stubber in
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

                remoteDataProviderMock.verify(.fetchDummyProducts(), count: .moreOrEqual(to: 1))

                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testShouldntFetchRemotelyIfDataIsAvailableLocally() {
        let expectation = self.expectation(description: "Expected to get data on success response")
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
            .fetchDummyProducts(willProduce: { stubber in
                let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((dataContainer, .local))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProducts(willProduce: { stubber in
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

                remoteDataProviderMock.verify(.fetchDummyProducts(), count: .exactly(0))

                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func tesShowErrorIfItCouldntFetchLocallyOrRemote() {
        let expectation = self.expectation(description: "Expected to get data on success response")
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
            .fetchDummyProducts(willProduce: { stubber in
                let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((dataContainer, .local))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        Given(
            remoteDataProviderMock,
            .fetchDummyProducts(willProduce: { stubber in
                let dataContainer: DummyProductDataContainer = ReadFile.object(from: "dummyProductTestsBundleOnly", extension: "json", bundle: Bundle(for: DummyProductsListViewTests.self))
                let publisher = CurrentValueSubject<(DummyProductDataContainer, DataProviderSource), Error>((dataContainer, .remote))
                publisher.send(completion: .failure(DataProviderError.invalidType))
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        subject.onAppear()

        subject
            .observableObject
            .$showErrorView
            .sink { showErrorView in
                XCTAssertTrue(showErrorView)
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }
}
