//
//  RandomNameSelectorViewModelTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import XCTest
import SwiftUI
import SwiftyMocky
import Combine

@testable import IRShowcaseMVP

final class RandomNameSelectorViewModelTests: TestCase {
    private var subject: RandomNameSelectorViewModelImpl!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    @MainActor
    func testDataGetsSetOnTheHappyPath() {
        let expectation = self.expectation(description: "Expected to get data on success response")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let dataProviderMock = FetchBabyNamePopularitiesProtocolMock()
        let routingMock = RandomNameSelectorScreenRoutingMock()
        subject = RandomNameSelectorViewModelImpl(
            routing: routingMock,
            dataProvider: dataProviderMock
        )

        Given(
            dataProviderMock,
            .fetchBabyNamePopularities(willProduce: { stubber in
                let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
                stubber.return(babyNamePopularities)
            })
        )

        subject.onAppear()
        
        subject
            .observableObject
            .$babyNamePopularities
            .dropFirst()
            .sink { array in
                XCTAssert(array.count > 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    @MainActor
    func testShowErrorViewBooleanIsTrueOnError() {
        let expectation = self.expectation(description: "Expected to the showErrorView boolean to be true on fetch error")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let dataProviderMock = FetchBabyNamePopularitiesProtocolMock()
        let routingMock = RandomNameSelectorScreenRoutingMock()
        let subject = RandomNameSelectorViewModelImpl(
            routing: routingMock,
            dataProvider: dataProviderMock
        )

        Given(
            dataProviderMock,
            .fetchBabyNamePopularities(willThrow: DataProviderError.noConnectivity)
        )

        XCTAssert(subject.observableObject.showErrorView == false)

        subject.onAppear()

        subject
            .observableObject
            .$showErrorView
            .dropFirst()
            .sink { showErrorView in
                XCTAssertTrue(showErrorView)
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    @MainActor
    func testButtonTapsSelectsCorrectGender() {
        let expectation = self.expectation(description: "Expected the selected baby name to have the last button tapped gender")
        defer { self.waitForExpectations(timeout: 10.0, handler: nil) }

        let dataProviderMock = FetchBabyNamePopularitiesProtocolMock()
        let routingMock = RandomNameSelectorScreenRoutingMock()
        subject = RandomNameSelectorViewModelImpl(
            routing: routingMock,
            dataProvider: dataProviderMock
        )

        Given(
            dataProviderMock,
            .fetchBabyNamePopularities(willProduce: { stubber in
                let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
                stubber.return(babyNamePopularities)
            })
        )

        subject.onAppear()

        subject
            .observableObject
            .$babyNamePopularities
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { _ in
                self.subject.onFemaleButtonTap()
                self.subject.onRandomButtonTap()
            }
            .store(in: &cancellables)

        subject
            .observableObject
            .$selectedBabyNamePopularity
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { selectedBabyNamePopularity in
                XCTAssertNotNil(selectedBabyNamePopularity)
                XCTAssertTrue(selectedBabyNamePopularity!.gender == .female)
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }
}
