//
//  NetworkParserTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//


import Foundation
import XCTest
import Combine

@testable import IRShowcaseMVP

class NetworkParserTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    func testPostsDecodingEncoding() {
        let expectation = self.expectation(description: "Expected to decode/encode properly")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
        XCTAssertTrue(babyNamePopularities.count == 101)
        var data: Data? = nil

        do {
            let jsonData = try JSONEncoder().encode(babyNamePopularities)
            data = jsonData
        } catch { XCTFail() }

        XCTAssertNotNil(data)

        let dpHandlersBuilder = DataProviderHandlersBuilder<[BabyNamePopularity]>()
        let networkParser = dpHandlersBuilder.standardNetworkParserHandler

        networkParser(data!)
            .sink { completion in
                // do nothing
            } receiveValue: { babyNames in
                XCTAssertTrue(babyNames.count == babyNamePopularities.count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testFailsWhenParsingWeirdData() {
        let expectation = self.expectation(description: "Expected to fail when encontering unknown data")
        defer { self.waitForExpectations(timeout: 3.0, handler: nil) }

        let data: Data? = NSData() as Data
        let dpHandlersBuilder = DataProviderHandlersBuilder<[BabyNamePopularity]>()
        let networkParser = dpHandlersBuilder.standardNetworkParserHandler

        networkParser(data!)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTAssertTrue(error.errorDescription == DataProviderError.parsing(error: DataProviderError.unknown).errorDescription)
                    expectation.fulfill()
                    break
                case .finished:
                    break
                }
            } receiveValue: { babyNames in
                XCTFail()
            }
            .store(in: &cancellables)
    }
}
