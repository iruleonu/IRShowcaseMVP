//
//  BabyNamePopularityDetailsScreenBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI

// Actions available from built childs
enum BabyNamePopularityDetailsScreenAction {
    // Empty
}

protocol BabyNamePopularityDetailsChildBuilders {
    // Empty
}

struct BabyNamePopularityDetailsScreenBuilder {
    func make(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView {
        let coordinator = BabyNamePopularityDetailsCoordinator(builders: self)
        let presenter = BabyNamePopularityDetailsPresenterImpl(routing: coordinator, babyNamePopularity: babyNamePopularity)
        return BabyNamePopularityDetailsView(presenter: presenter)
    }
}

extension BabyNamePopularityDetailsScreenBuilder: BabyNamePopularityDetailsChildBuilders {

}
