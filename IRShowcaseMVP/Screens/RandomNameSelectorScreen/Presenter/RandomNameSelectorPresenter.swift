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

final class RandomNameSelectorViewModel: ObservableObject {
    @Published var navBarTitle = "Popular baby names"
    @Published var babyNamePopularities: [BabyNamePopularity] = []
    @Published var selectedBabyNamePopularity: BabyNamePopularity?
    @Published var showErrorView: Bool = false
}

// sourcery: AutoMockable
protocol RandomNameSelectorPresenter {
    var viewModel: RandomNameSelectorViewModel { get }
    func onAppear()
    func onFemaleButtonTap()
    func onRandomButtonTap()
    func onMaleButtonTap()
    func navigateToBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView
}

final class RandomNameSelectorPresenterImpl: RandomNameSelectorPresenter {
    private(set) var routing: RandomNameSelectorScreenRouting
    private var dataProvider: FetchBabyNamePopularitiesProtocol
    var viewModel: RandomNameSelectorViewModel
    private var currentGender: Gender

    private var cancellables = Set<AnyCancellable>()

    init(routing: RandomNameSelectorScreenRouting, dataProvider: FetchBabyNamePopularitiesProtocol) {
        self.routing = routing
        self.dataProvider = dataProvider
        self.viewModel = RandomNameSelectorViewModel()
        currentGender = Gender.unknown
    }

    func onAppear() {
        fetchPopularBabyNames()
    }

    private func fetchPopularBabyNames() {
        dataProvider.fetchBabyNamePopularities()
            .catch({ [weak self] error -> Empty<BabyNamePopularityDataContainer, Never> in
                guard let self = self else { return Empty<BabyNamePopularityDataContainer, Never>() }
                self.viewModel.showErrorView = true
                return Empty<BabyNamePopularityDataContainer, Never>()
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] babyNamePopularitiesDataContainer in
                guard let self = self else { return }
                self.viewModel.babyNamePopularities = babyNamePopularitiesDataContainer.babyNamePopularityRepresentation
            }
            .store(in: &cancellables)
    }
}

extension RandomNameSelectorPresenterImpl {
    func navigateToBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView {
        return self.routing.buildBabyNamePopularityDetails(babyNamePopularity: babyNamePopularity)
    }

    func onFemaleButtonTap() {
        currentGender = .female
    }

    func onRandomButtonTap() {
        guard currentGender != .unknown,
            let babyNamePopularity = selectOneRandomName(fromBabyNames: self.viewModel.babyNamePopularities, gender: currentGender)
        else {
            return
        }
        self.viewModel.selectedBabyNamePopularity = babyNamePopularity
    }

    func onMaleButtonTap() {
        currentGender = .male
    }
}

private extension RandomNameSelectorPresenterImpl {
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