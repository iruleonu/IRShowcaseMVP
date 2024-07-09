//
//  FetchBabyNamePopularity.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

// sourcery: AutoMockable
protocol FetchBabyNamePopularitiesProtocol {
    @DataProviderActor
    func fetchBabyNamePopularities() async throws -> BabyNamePopularityDataContainer
}
