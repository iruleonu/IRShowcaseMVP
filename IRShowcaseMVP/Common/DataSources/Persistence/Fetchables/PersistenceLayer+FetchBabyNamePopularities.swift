//
//  PersistenceLayer+FetchBabyNamePopularities.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension PersistenceLayerImpl: FetchBabyNamePopularitiesProtocol {
    func fetchBabyNamePopularities() async throws -> BabyNamePopularityDataContainer {
        do {
            let values: BabyNamePopularityDataContainer = try await self.fetchResource(.babyNamePopularities)
            return values
        } catch {
            throw PersistenceLayerError.persistence(error: error)
        }
    }
}
