//
//  RandomNameSelectorScreenCoordinator.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import UIKit

// sourcery: AutoMockable
@MainActor
protocol RandomNameSelectorScreenRouting: Sendable {
    func makeBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView
}

final class RandomNameSelectorScreenCoordinator: RandomNameSelectorScreenRouting {
    private let builders: RandomNameSelectorScreenChildBuilders
    private let dataProvider: FetchBabyNamePopularitiesProtocol

    init(builders b: RandomNameSelectorScreenChildBuilders, dataProvider dp: FetchBabyNamePopularitiesProtocol) {
        builders = b
        dataProvider = dp
    }

    func makeBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView {
        return builders.makeBabyNamePopularityDetails(babyNamePopularity: babyNamePopularity)
    }
}
