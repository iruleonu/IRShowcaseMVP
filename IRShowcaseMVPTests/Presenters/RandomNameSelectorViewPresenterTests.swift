//
//  RandomNameSelectorViewPresenterTests.swift
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

final class RandomNameSelectorViewPresenterTests: TestCase {
    private var subject: RandomNameSelectorPresenterImpl!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    func testDataGetsSetOnTheHappyPath() {
        let expectation = self.expectation(description: "Expected to get data on success response")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let dataProviderMock = FetchBabyNamePopularitiesProtocolMock()
        let routingMock = RandomNameSelectorScreenRoutingMock()
        subject = RandomNameSelectorPresenterImpl(
            routing: routingMock,
            dataProvider: dataProviderMock
        )

        Given(
            dataProviderMock,
            .fetchBabyNamePopularities(willProduce: { stubber in
                let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
                let publisher = CurrentValueSubject<[BabyNamePopularity], Error>(babyNamePopularities)
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        subject.onAppear()
        
        subject
            .viewModel
            .$babyNamePopularities
            .dropFirst()
            .sink { array in
                XCTAssert(array.count > 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testShowErrorViewBooleanIsTrueOnError() {
        let expectation = self.expectation(description: "Expected to the showErrorView boolean to be true on fetch error")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        let dataProviderMock = FetchBabyNamePopularitiesProtocolMock()
        let routingMock = RandomNameSelectorScreenRoutingMock()
        let subject = RandomNameSelectorPresenterImpl(
            routing: routingMock,
            dataProvider: dataProviderMock
        )

        Given(
            dataProviderMock,
            .fetchBabyNamePopularities(willProduce: { stubber in
                let passthroughSubject = PassthroughSubject<[BabyNamePopularity], Error>()
                stubber.return(passthroughSubject.eraseToAnyPublisher())
                passthroughSubject.send(completion: .failure(DataProviderError.noConnectivity))
            })
        )

        XCTAssert(subject.viewModel.showErrorView == false)

        subject.onAppear()

        subject
            .viewModel
            .$showErrorView
            .sink { showErrorView in
                XCTAssertTrue(showErrorView)
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testButtonTapsSelectsCorrectGender() {
        let expectation = self.expectation(description: "Expected the selected baby name to have the last button tapped gender")
        defer { self.waitForExpectations(timeout: 10.0, handler: nil) }

        let dataProviderMock = FetchBabyNamePopularitiesProtocolMock()
        let routingMock = RandomNameSelectorScreenRoutingMock()
        subject = RandomNameSelectorPresenterImpl(
            routing: routingMock,
            dataProvider: dataProviderMock
        )

        Given(
            dataProviderMock,
            .fetchBabyNamePopularities(willProduce: { stubber in
                let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
                let publisher = CurrentValueSubject<[BabyNamePopularity], Error>(babyNamePopularities)
                stubber.return(publisher.eraseToAnyPublisher())
            })
        )

        subject.onAppear()

        subject
            .viewModel
            .$babyNamePopularities
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { _ in
                self.subject.onFemaleButtonTap()
            }
            .store(in: &cancellables)

        subject
            .viewModel
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
