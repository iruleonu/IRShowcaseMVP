//
//  RandomNameSelectorViewTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import XCTest
import SwiftUI
import SwiftyMocky
import OrderedCollections

@testable import IRShowcaseMVP

final class RandomNameSelectorViewTests: TestCase {
    func testSnapshotRandomNameSelectorView_NoSelection() {
        // Given
        let view = RandomNameSelectorView(
            presenter: makePresenter(
                observableObject: .stub()
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }

    func testSnapshotRandomNameSelectorView_FirstSelected() {
        // Given
        let view = RandomNameSelectorView(
            presenter: makePresenter(
                observableObject: .stub(selectFirstName: true)
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }

    func testSnapshotRandomNameSelectorView_ErrorView() {
        // Given
        let view = RandomNameSelectorView(
            presenter: makePresenter(
                observableObject: .stub(showErrorView: true)
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }
}

// MARK: - Private methods
private extension RandomNameSelectorViewTests {
    func makePresenter(observableObject: RandomNameSelectorViewObservableObject) -> RandomNameSelectorViewModelMock {
        let presenterMock = RandomNameSelectorViewModelMock()

        Given(
            presenterMock,
            .observableObject(getter: observableObject)
        )

        Given(
            presenterMock,
            .navigateToBabyNamePopularityDetails(
                babyNamePopularity: .any,
                willReturn: BabyNamePopularityDetailsView(
                    presenter: makeBabyNamePopularityDetailsViewPresenter(
                        observableObject: .init(babyNamePopularity: .stub())
                    )
                )
            )
        )

        return presenterMock
    }

    func makeBabyNamePopularityDetailsViewPresenter(observableObject: BabyNamePopularityDetailsViewObservableObject) -> BabyNamePopularityDetailsViewModelMock {
        let presenterMock = BabyNamePopularityDetailsViewModelMock()

        Given(
            presenterMock,
            .observableObject(getter: observableObject)
        )

        return presenterMock
    }
}

private extension RandomNameSelectorViewObservableObject {
    static func stub(selectFirstName: Bool = false, showErrorView: Bool = false) -> RandomNameSelectorViewObservableObject {
        let vm = RandomNameSelectorViewObservableObject()

        let babyNamePopularitiesDataContainer: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
        let orderedSet = OrderedSet(babyNamePopularitiesDataContainer.babyNamePopularityRepresentation)
        vm.babyNamePopularities = Array(orderedSet)

        if (selectFirstName) {
            vm.selectedBabyNamePopularity = orderedSet.first
        }

        vm.showErrorView = showErrorView

        return vm
    }
}

private extension BabyNamePopularity {
    static func stub() -> BabyNamePopularity {
        .init(yearOfBirth: 1, gender: .female, ethnicity: "", name: "", numberOfBabiesWithSameName: 1, nameRank: 1)
    }
}
