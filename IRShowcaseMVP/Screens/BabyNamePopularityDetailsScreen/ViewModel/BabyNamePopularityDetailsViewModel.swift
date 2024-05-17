//
//  BabyNamePopularityDetailsViewModel.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class BabyNamePopularityDetailsViewObservableObject: ObservableObject {
    @Published var yearOfBirth: String
    @Published var gender: Gender
    @Published var ethnicity: String
    @Published var name: String
    @Published var numberOfBabiesWithSameName: String
    @Published var nameRank: String

    init(babyNamePopularity: BabyNamePopularity) {
        self.yearOfBirth = String(babyNamePopularity.yearOfBirth)
        self.gender = babyNamePopularity.gender
        self.ethnicity = babyNamePopularity.ethnicity
        self.name = babyNamePopularity.name
        self.numberOfBabiesWithSameName = String(babyNamePopularity.numberOfBabiesWithSameName)
        self.nameRank = String(babyNamePopularity.nameRank)
    }
}

// sourcery: AutoMockable
protocol BabyNamePopularityDetailsViewModel {
    var observableObject: BabyNamePopularityDetailsViewObservableObject { get }
    func onAppear()
}

final class BabyNamePopularityDetailsViewModelImpl: BabyNamePopularityDetailsViewModel {
    var observableObject: BabyNamePopularityDetailsViewObservableObject
    private(set) var routing: BabyNamePopularityDetailsRouting
    
    init(routing: BabyNamePopularityDetailsRouting, babyNamePopularity: BabyNamePopularity) {
        self.observableObject = BabyNamePopularityDetailsViewObservableObject(babyNamePopularity: babyNamePopularity)
        self.routing = routing
    }

    func onAppear() {
        // do nothing
    }
}
