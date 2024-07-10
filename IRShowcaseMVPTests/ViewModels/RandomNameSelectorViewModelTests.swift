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

    func testDataGetsSetOnTheHappyPath() async {
        let expectation = self.expectation(description: "Expected to get data on success response")
        
        Task { @MainActor in
            let dataProviderMock = FetchBabyNamePopularitiesProtocolMock()
            let routingMock = RandomNameSelectorScreenRoutingMock()
            self.subject = RandomNameSelectorViewModelImpl(
                routing: routingMock,
                dataProvider: dataProviderMock
            )
            
            Task { @DataProviderActor in
                Given(
                    dataProviderMock,
                    .fetchBabyNamePopularities(willProduce: { stubber in
                        let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json", bundle: Bundle(for: RandomNameSelectorViewModelTests.self))
                        stubber.return(babyNamePopularities)
                    })
                )
            }
            
            self.subject.onAppear()
            
            self.subject
                .observableObject
                .$babyNamePopularities
                .dropFirst()
                .sink { array in
                    XCTAssert(array.count > 0)
                    expectation.fulfill()
                }
                .store(in: &self.cancellables)
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testShowErrorViewBooleanIsTrueOnError() async {
        let expectation = self.expectation(description: "Expected to the showErrorView boolean to be true on fetch error")
        
        Task { @MainActor in
            let dataProviderMock = FetchBabyNamePopularitiesProtocolMock()
            let routingMock = RandomNameSelectorScreenRoutingMock()
            self.subject = RandomNameSelectorViewModelImpl(
                routing: routingMock,
                dataProvider: dataProviderMock
            )
            
            Task { @DataProviderActor in
                Given(
                    dataProviderMock,
                    .fetchBabyNamePopularities(willThrow: DataProviderError.noConnectivity)
                )
            }

            XCTAssert(self.subject.observableObject.showErrorView == false)

            self.subject.onAppear()

            self.subject
                .observableObject
                .$showErrorView
                .dropFirst()
                .sink { showErrorView in
                    XCTAssertTrue(showErrorView)
                    expectation.fulfill()
                }
                .store(in: &self.cancellables)
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testButtonTapsSelectsCorrectGender() async {
        let expectation = self.expectation(description: "Expected the selected baby name to have the last button tapped gender")

        Task { @MainActor in
            let dataProviderMock = FetchBabyNamePopularitiesProtocolMock()
            let routingMock = RandomNameSelectorScreenRoutingMock()
            self.subject = RandomNameSelectorViewModelImpl(
                routing: routingMock,
                dataProvider: dataProviderMock
            )
            
            Task { @DataProviderActor in
                Given(
                    dataProviderMock,
                    .fetchBabyNamePopularities(willReturn: {
                        let babyNamePopularitiesDataContainer: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json", bundle: Bundle(for: RandomNameSelectorViewModelTests.self))
                        return babyNamePopularitiesDataContainer
                    }())
                )
            }

            self.subject.onAppear()

            self.subject
                .observableObject
                .$babyNamePopularities
                .receive(on: DispatchQueue.main)
                .dropFirst()
                .sink { showErrorView in
                    self.subject.onFemaleButtonTap()
                    self.subject.onRandomButtonTap()
                }
                .store(in: &self.cancellables)
            
            self.subject
                .observableObject
                .$selectedBabyNamePopularity
                .receive(on: DispatchQueue.main)
                .dropFirst()
                .sink { selectedBabyNamePopularity in
                    XCTAssertNotNil(selectedBabyNamePopularity)
                    XCTAssertTrue(selectedBabyNamePopularity!.gender == .female)
                    expectation.fulfill()
                }
                .store(in: &self.cancellables)
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}
