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
    func onMaleButtonTap()
    func navigateToBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView
}

final class RandomNameSelectorPresenterImpl: RandomNameSelectorPresenter {
    private(set) var routing: RandomNameSelectorScreenRouting
    private var dataProvider: FetchBabyNamePopularitiesProtocol
    var viewModel: RandomNameSelectorViewModel

    private var cancellables = Set<AnyCancellable>()

    init(routing: RandomNameSelectorScreenRouting, dataProvider: FetchBabyNamePopularitiesProtocol) {
        self.routing = routing
        self.dataProvider = dataProvider
        self.viewModel = RandomNameSelectorViewModel()
    }

    func onAppear() {
        fetchPopularBabyNames()
    }

    private func fetchPopularBabyNames() {
        dataProvider.fetchBabyNamePopularities()
            .catch({ [weak self] error -> Empty<[BabyNamePopularity], Never> in
                guard let self = self else { return Empty<[BabyNamePopularity], Never>() }
                self.viewModel.showErrorView = true
                return Empty<[BabyNamePopularity], Never>()
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] babyNamePopularities in
                guard let self = self else { return }
                self.viewModel.babyNamePopularities = babyNamePopularities
            }
            .store(in: &cancellables)
    }
}

extension RandomNameSelectorPresenterImpl {
    func navigateToBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView {
        return self.routing.buildBabyNamePopularityDetails(babyNamePopularity: babyNamePopularity)
    }

    func onFemaleButtonTap() {
        guard let babyNamePopularity = selectOneRandomFemale(fromBabyNames: self.viewModel.babyNamePopularities) else { return }
        self.viewModel.selectedBabyNamePopularity = babyNamePopularity
    }

    func onMaleButtonTap() {
        guard let babyNamePopularity = selectOneRandomMale(fromBabyNames: self.viewModel.babyNamePopularities) else { return }
        self.viewModel.selectedBabyNamePopularity = babyNamePopularity
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
