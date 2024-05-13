//
//  RandomNameSelectorScreenBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI

// Actions available from childs built from PostsListChildBuilders
enum RandomNameSelectorScreenAction {
    // Empty
}

protocol RandomNameSelectorScreenChildBuilders {
    func makeBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView
}

struct RandomNameSelectorScreenBuilder {
    func make(dataProvider: FetchBabyNamePopularitiesProtocol) -> RandomNameSelectorView {
        let coordinator = RandomNameSelectorScreenCoordinator(builders: self, dataProvider: dataProvider)
        let presenter = RandomNameSelectorPresenterImpl(routing: coordinator, dataProvider: dataProvider)
        return RandomNameSelectorView(presenter: presenter)
    }
}

extension RandomNameSelectorScreenBuilder: RandomNameSelectorScreenChildBuilders {
    func makeBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView {
        return BabyNamePopularityDetailsScreenBuilder().make(babyNamePopularity: babyNamePopularity)
    }
}
