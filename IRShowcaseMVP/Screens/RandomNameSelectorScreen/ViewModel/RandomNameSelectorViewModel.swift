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
    @MainActor func onAppear()
    @MainActor func onFemaleButtonTap()
    @MainActor func onRandomButtonTap()
    @MainActor func onMaleButtonTap()
    @MainActor func navigateToBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView
}

final class RandomNameSelectorViewModelImpl: RandomNameSelectorViewModel {
    private(set) var routing: RandomNameSelectorScreenRouting
    private var dataProvider: FetchBabyNamePopularitiesProtocol
    var observableObject: RandomNameSelectorViewObservableObject
    private var currentGender: Gender

    private var cancellables = Set<AnyCancellable>()

    @MainActor
    init(routing: RandomNameSelectorScreenRouting, dataProvider: FetchBabyNamePopularitiesProtocol) {
        self.routing = routing
        self.dataProvider = dataProvider
        self.observableObject = RandomNameSelectorViewObservableObject()
        currentGender = Gender.unknown
    }
}

extension RandomNameSelectorViewModelImpl {
    @MainActor
    func onAppear() {
        Task { @MainActor in
            await fetchPopularBabyNames()
        }
    }

    @MainActor
    func navigateToBabyNamePopularityDetails(babyNamePopularity: BabyNamePopularity) -> BabyNamePopularityDetailsView {
        return self.routing.makeBabyNamePopularityDetails(babyNamePopularity: babyNamePopularity)
    }

    @MainActor
    func onFemaleButtonTap() {
        currentGender = .female
    }

    @MainActor
    func onRandomButtonTap() {
        guard currentGender != .unknown,
            let babyNamePopularity = selectOneRandomName(fromBabyNames: self.observableObject.babyNamePopularities, gender: currentGender)
        else {
            return
        }
        self.observableObject.selectedBabyNamePopularity = babyNamePopularity
    }

    @MainActor
    func onMaleButtonTap() {
        currentGender = .male
    }
}

private extension RandomNameSelectorViewModelImpl {
    @MainActor
    private func fetchPopularBabyNames() async {
        let fetchResult: Result<BabyNamePopularityDataContainer, Error>
        do {
            let value = try await dataProvider.fetchBabyNamePopularities()
            fetchResult = .success(value)
        } catch {
            fetchResult = .failure(error)
        }

        switch fetchResult {
        case .success(let babyNamePopularitiesDataContainer):
            let noDuplicates = Set(self.observableObject.babyNamePopularities).union(Set(babyNamePopularitiesDataContainer.babyNamePopularityRepresentation))
            self.observableObject.babyNamePopularities = Array(noDuplicates)
        case .failure:
            self.observableObject.showErrorView = true
        }
    }

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
