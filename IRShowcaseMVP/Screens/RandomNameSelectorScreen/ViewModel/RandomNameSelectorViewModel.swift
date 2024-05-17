//
//  RandomNameSelectorViewModel.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class RandomNameSelectorViewObservableObject: ObservableObject {
    @Published var navBarTitle = "Popular baby names"
    @Published var babyNamePopularities: [BabyNamePopularity] = []
    @Published var selectedBabyNamePopularity: BabyNamePopularity?
    @Published var showErrorView: Bool = false
}

// sourcery: AutoMockable
protocol RandomNameSelectorViewModel {
    var observableObject: RandomNameSelectorViewObservableObject { get }
    func onAppear()
    func onFemaleButtonTap()
    func onRandomButtonTap()
    func onMaleButtonTap()
    func navigateToBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView
}

final class RandomNameSelectorViewModelImpl: RandomNameSelectorViewModel {
    private(set) var routing: RandomNameSelectorScreenRouting
    private var dataProvider: FetchBabyNamePopularitiesProtocol
    var observableObject: RandomNameSelectorViewObservableObject
    private var currentGender: Gender

    private var cancellables = Set<AnyCancellable>()

    init(routing: RandomNameSelectorScreenRouting, dataProvider: FetchBabyNamePopularitiesProtocol) {
        self.routing = routing
        self.dataProvider = dataProvider
        self.observableObject = RandomNameSelectorViewObservableObject()
        currentGender = Gender.unknown
    }

    func onAppear() {
        fetchPopularBabyNames()
    }

    private func fetchPopularBabyNames() {
        dataProvider.fetchBabyNamePopularities()
            .catch({ [weak self] error -> Empty<BabyNamePopularityDataContainer, Never> in
                guard let self = self else { return Empty<BabyNamePopularityDataContainer, Never>() }
                self.observableObject.showErrorView = true
                return Empty<BabyNamePopularityDataContainer, Never>()
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] babyNamePopularitiesDataContainer in
                guard let self = self else { return }
                let noDuplicates = Set(self.observableObject.babyNamePopularities).union(Set(babyNamePopularitiesDataContainer.babyNamePopularityRepresentation))
                self.observableObject.babyNamePopularities = Array(noDuplicates)
            }
            .store(in: &cancellables)
    }
}

extension RandomNameSelectorViewModelImpl {
    func navigateToBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView {
        return self.routing.buildBabyNamePopularityDetails(babyNamePopularity: babyNamePopularity)
    }

    func onFemaleButtonTap() {
        currentGender = .female
    }

    func onRandomButtonTap() {
        guard currentGender != .unknown,
            let babyNamePopularity = selectOneRandomName(fromBabyNames: self.observableObject.babyNamePopularities, gender: currentGender)
        else {
            return
        }
        self.observableObject.selectedBabyNamePopularity = babyNamePopularity
    }

    func onMaleButtonTap() {
        currentGender = .male
    }
}

private extension RandomNameSelectorViewModelImpl {
    private func selectOneRandomFemale(fromBabyNames babyNames: [BabyNamePopularity]) -> BabyNamePopularity? {
        return selectOneRandomName(fromBabyNames: babyNames, gender: .female)
    }

    private func selectOneRandomMale(fromBabyNames babyNames: [BabyNamePopularity]) -> BabyNamePopularity? {
        return selectOneRandomName(fromBabyNames: babyNames, gender: .male)
    }

    private func selectOneRandomName(fromBabyNames babyNames: [BabyNamePopularity], gender: Gender) -> BabyNamePopularity? {
        let aux = babyNames.filter({ $0.gender == gender })
        guard aux.count > 0 else { return nil }
        let randomInt = Int.random(in: 0..<aux.count)
        return randomInt < aux.count ? aux[randomInt] : aux.first
    }
}
