//
//  BabyNamePopularityDetailsCoordinator.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import UIKit

// sourcery: AutoMockable
protocol BabyNamePopularityDetailsRouting {

}

final class BabyNamePopularityDetailsCoordinator {
    private let builders: BabyNamePopularityDetailsChildBuilders

    init(builders b: BabyNamePopularityDetailsChildBuilders) {
        builders = b
    }
}

extension BabyNamePopularityDetailsCoordinator: BabyNamePopularityDetailsRouting {

}
