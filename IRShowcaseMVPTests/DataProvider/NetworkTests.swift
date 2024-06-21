//
//  NetworkTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Testing
import Foundation
import SwiftyMocky

@testable import IRShowcaseMVP

struct NetworkTests {
    private let network = APIServiceMock()
    private let networkHandler = DataProviderHandlersBuilder<DummyProductDataContainer>().standardNetworkHandler

    @Test func testSuccessfulRequest() async throws {
        Given(
            network,
            .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!))
        )

        Given(
            network,
            .fetchData(
                request: .any,
                willReturn: (Data(), URLResponse())
            )
        )

        let value = try await networkHandler(network, network.buildUrlRequest(resource: .dummyProductsAll))
        #expect(value != nil)
    }

    @Test func testFailedRequest() async throws {
        Given(
            network,
            .buildUrlRequest(resource: .any, willReturn: Resource.dummyProductsAll.buildUrlRequest(apiBaseUrl: URL(string: "https://fake.com")!))
        )

        Given(
            network,
            .fetchData(request: .any, willThrow: DataProviderError.unknown)
        )

        await #expect(throws: DataProviderError.unknown) {
            try await networkHandler(network, network.buildUrlRequest(resource: .dummyProductsAll))
        }
    }
}
