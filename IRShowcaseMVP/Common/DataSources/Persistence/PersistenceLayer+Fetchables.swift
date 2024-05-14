//
//  PersistenceLayer+Fetchables.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension PersistenceLayerImpl: FetchBabyNamePopularitiesProtocol {
    func fetchBabyNamePopularities() -> AnyPublisher<BabyNamePopularityDataContainer, Error> {
        return self.fetchResource(.babyNamePopularities)
            .mapError({ PersistenceLayerError.persistence(error: $0) })
            .eraseToAnyPublisher()
    }
}
