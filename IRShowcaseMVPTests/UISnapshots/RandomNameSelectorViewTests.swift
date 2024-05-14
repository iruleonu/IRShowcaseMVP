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
@testable import IRShowcaseMVP

final class RandomNameSelectorViewTests: TestCase {
    func testSnapshotRandomNameSelectorView_NoSelection() {
        // Given
        let view = RandomNameSelectorView(
            presenter: makePresenter(
                viewModel: .stub()
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }

    func testSnapshotRandomNameSelectorView_FirstSelected() {
        // Given
        let view = RandomNameSelectorView(
            presenter: makePresenter(
                viewModel: .stub(selectFirstName: true)
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }

    func testSnapshotRandomNameSelectorView_ErrorView() {
        // Given
        let view = RandomNameSelectorView(
            presenter: makePresenter(
                viewModel: .stub(showErrorView: true)
            )
        )

        // Then
        cwSnapshotOnDevices(view: view)
    }
}

// MARK: - Private methods
private extension RandomNameSelectorViewTests {
    func makePresenter(viewModel: RandomNameSelectorViewModel) -> RandomNameSelectorPresenterMock {
        let presenterMock = RandomNameSelectorPresenterMock()

        Given(
            presenterMock,
            .viewModel(getter: viewModel)
        )

        Given(
            presenterMock,
            .navigateToBabyNamePopularityDetails(
                babyNamePopularity: .any,
                willReturn: BabyNamePopularityDetailsView(
                    presenter: makeBabyNamePopularityDetailsViewPresenter(
                        viewModel: .init(babyNamePopularity: .stub())
                    )
                )
            )
        )

        return presenterMock
    }

    func makeBabyNamePopularityDetailsViewPresenter(viewModel: BabyNamePopularityDetailsViewModel) -> BabyNamePopularityDetailsPresenterMock {
        let presenterMock = BabyNamePopularityDetailsPresenterMock()
        
        Given(
            presenterMock,
            .viewModel(getter: viewModel)
        )

        return presenterMock
    }
}

private extension RandomNameSelectorViewModel {
    static func stub(selectFirstName: Bool = false, showErrorView: Bool = false) -> RandomNameSelectorViewModel {
        let vm = RandomNameSelectorViewModel()

        let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
        vm.babyNamePopularities = babyNamePopularities.babyNamePopularityRepresentation

        if (selectFirstName) {
            vm.selectedBabyNamePopularity = babyNamePopularities.babyNamePopularityRepresentation.first
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
