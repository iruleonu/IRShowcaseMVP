//
//  PersistenceTests.swift
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

class PersistenceTests: XCTestCase {
    private var persistence: PersistenceLayerMock!
    private var persistenceLoadHandler: DataProviderHandlers<[BabyNamePopularity]>.PersistenceLoadHandler!
    private var persistenceSaveHandler: DataProviderHandlers<[BabyNamePopularity]>.PersistenceSaveHandler!
    private var persistenceRemoveHandler: DataProviderHandlers<[BabyNamePopularity]>.PersistenceRemoveHandler!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        persistence = PersistenceLayerMock()
        let dpHandlersBuilder = DataProviderHandlersBuilder<[BabyNamePopularity]>()
        persistenceLoadHandler = dpHandlersBuilder.standardPersistenceLoadHandler
        persistenceSaveHandler = dpHandlersBuilder.standardPersistenceSaveHandler
        persistenceRemoveHandler = dpHandlersBuilder.standardPersistenceRemoveHandler
    }

    override func tearDown() {
        persistence = nil
        persistenceLoadHandler = nil
        persistenceSaveHandler = nil
        persistenceRemoveHandler = nil
        super.tearDown()
    }

    func testShouldLoadIfSuccess() {
        let expectation = self.expectation(description: "Expected load data when found resource")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        Given(
            persistence,
            .fetchResource(
                .any,
                willReturn: {
                    let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
                    return CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>(babyNamePopularities).eraseToAnyPublisher()
                }()
            )
        )

        persistenceLoadHandler(persistence, .babyNamePopularities)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    XCTFail()
                }
            } receiveValue: { babyNames in
                XCTAssertTrue(babyNames.count > 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testFailToLoadIfError() {
        let expectation = self.expectation(description: "Expected to fail when doesnt know the resource")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        Given(
            persistence,
            .fetchResource(
                .any,
                willReturn: {
                    let babyNamePopularities: [BabyNamePopularity] = ReadFile.object(from: "babyNamePopularities", extension: "json")
                    let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>(babyNamePopularities)
                    publisher.send(completion: .failure(PersistenceLayerError.persistence(error: NSError.error(withMessage: "No known resource"))))
                    return publisher.eraseToAnyPublisher()
                }()
            )
        )

        persistenceLoadHandler(persistence, .babyNamePopularities)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    expectation.fulfill()
                }
            } receiveValue: { babyNames in
                XCTFail()
            }
            .store(in: &cancellables)
    }

    func testThrowErrorIfEmptyResultsForResource() {
        let expectation = self.expectation(description: "Expected to return an error if there was no results for the requested resource")
        defer { self.waitForExpectations(timeout: 1.0, handler: nil) }

        Given(
            persistence,
            .fetchResource(
                .any,
                willReturn: {
                    let publisher = CurrentValueSubject<[BabyNamePopularity], PersistenceLayerError>([])
                    publisher.send(completion: .failure(PersistenceLayerError.emptyResult(error: NSError.error(withMessage: "No results"))))
                    return publisher.eraseToAnyPublisher()
                }()
            )
        )

        persistenceLoadHandler(persistence, .babyNamePopularities)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    expectation.fulfill()
                }
            } receiveValue: { babyNames in
                XCTFail()
            }
            .store(in: &cancellables)
    }

    func testSucceedIfSuccessSaving() {
        let expectation = self.expectation(description: "Expected success when saving")
        defer { self.waitForExpectations(timeout: 3.0, handler: nil) }

        persistence.perform(.persistObjects(Parameter<[BabyNamePopularity]>.any, saveCompletion: .any, perform: { _, block in
            block(true, nil)
        }))

        persistenceSaveHandler(persistence, [])
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    XCTFail()
                }
            } receiveValue: { babyNames in
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testFailureIfErrorSaving() {
        let expectation = self.expectation(description: "Expected failure when there was an error saving")
        defer { self.waitForExpectations(timeout: 3.0, handler: nil) }

        persistence.perform(.persistObjects(Parameter<[BabyNamePopularity]>.any, saveCompletion: .any, perform: { _, block in
            let error = PersistenceLayerError.emptyResult(error: NSError.error(withMessage: "Error"))
            block(false, error)
        }))

        persistenceSaveHandler(persistence, [])
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    expectation.fulfill()
                }
            } receiveValue: { babyNames in
                XCTFail()
            }
            .store(in: &cancellables)
    }

    func testSucceedIfSuccessRemoving() {
        let expectation = self.expectation(description: "Expected success when resource was sucessfuly removed")
        defer { self.waitForExpectations(timeout: 3.0, handler: nil) }

        Given(
            persistence,
            .removeResource(
                .any,
                willReturn: {
                    let publisher = CurrentValueSubject<Bool, PersistenceLayerError>(true)
                    return publisher.eraseToAnyPublisher()
                }()
            )
        )

        persistenceRemoveHandler(persistence, .babyNamePopularities)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    XCTFail()
                }
            } receiveValue: { babyNames in
                expectation.fulfill()
            }
            .store(in: &cancellables)
    }

    func testErrorIfFailureRemoving() {
        let expectation = self.expectation(description: "Expected error when failure removing")
        defer { self.waitForExpectations(timeout: 3.0, handler: nil) }

        Given(
            persistence,
            .removeResource(
                .any,
                willReturn: {
                    let publisher = CurrentValueSubject<Bool, PersistenceLayerError>(true)
                    let error = PersistenceLayerError.emptyResult(error: NSError.error(withMessage: "No results"))
                    publisher.send(completion: .failure(error))
                    return publisher.eraseToAnyPublisher()
                }()
            )
        )

        persistenceRemoveHandler(persistence, .babyNamePopularities)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    expectation.fulfill()
                }
            } receiveValue: { babyNames in
                XCTFail()
            }
            .store(in: &cancellables)
    }
}
