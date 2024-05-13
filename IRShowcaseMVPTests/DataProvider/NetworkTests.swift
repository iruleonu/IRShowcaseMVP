//
//  NetworkTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import XCTest
import SwiftyMocky
import Combine

@testable import IRShowcaseMVP

class NetworkTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!
    private var network: APIServiceMock!
    private var networkHandler: DataProviderHandlers<[BabyNamePopularity]>.NetworkHandler!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        network = APIServiceMock()
        let dpHandlersBuilder = DataProviderHandlersBuilder<[BabyNamePopularity]>()
        networkHandler = dpHandlersBuilder.standardNetworkHandler
    }

    override func tearDown() {
        network = nil
        networkHandler = nil
        super.tearDown()
    }

    func testSuccessfulRequest() {
        let expectation = self.expectation(description: "Expected request to return data")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        Given(
            network,
            .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!))
        )

        Given(
            network,
            .fetchData(
                request: .any,
                willReturn: CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse())).eraseToAnyPublisher()
            )
        )

        networkHandler(network,network.buildUrlRequest(resource: .unknown))
                .sink { completion in
                    XCTFail()
                } receiveValue: { babyNames in
                    expectation.fulfill()
                }
                .store(in: &cancellables)
    }

    func testFailedRequest() {
        let expectation = self.expectation(description: "Expected request to fail")
        defer { self.waitForExpectations(timeout: 3.0, handler: nil) }

        Given(
            network,
            .buildUrlRequest(resource: .any, willReturn: Resource.babyNamePopularities.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!))
        )

        let publisher = CurrentValueSubject<(Data, URLResponse), DataProviderError>((Data(), URLResponse()))
        publisher.send(completion: .failure(DataProviderError.requestError(error: DataProviderError.unknown)))
        Given(
            network,
            .fetchData(
                request: .any,
                willReturn: publisher.eraseToAnyPublisher()
            )
        )

        networkHandler(network,network.buildUrlRequest(resource: .unknown))
                .sink { completion in
                    expectation.fulfill()
                } receiveValue: { babyNames in
                    XCTFail()
                }
                .store(in: &cancellables)
    }
}
