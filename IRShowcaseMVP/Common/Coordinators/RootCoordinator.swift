//
//  RootCoordinator.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 20/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation
import UIKit

@MainActor
protocol RootRouting {
    func start()
}

final class RootCoordinator: RootRouting {
    enum LaunchFlow {
        case productsListThatFetchsAllProductsInOneRequest
        case productsListThatFetchsAllProductsInOneRequestOnAHybridDataProvider
        case productsListWithPagination
        case productsListWithPaginationOnAHybridDataProvider
        case popularBabyNames
    }
    
    private var window: UIWindow
    private let builders: RootCoordinatorChildBuilders
    private let launchFlow: LaunchFlow

    init(
        window w: UIWindow,
        builders b: RootCoordinatorChildBuilders,
        launchFlow lf: LaunchFlow
    ) {
        window = w
        builders = b
        launchFlow = lf
    }

    @MainActor 
    func start() {
        handleLaunchFlow(launchFlow)
    }
}

@MainActor
private extension RootCoordinator {
    func handleLaunchFlow(_ launchFlow: LaunchFlow) {
        switch launchFlow {
        case .productsListThatFetchsAllProductsInOneRequest:
            launchProductsListThatFetchsAllProductsInOneRequest()
        case .productsListThatFetchsAllProductsInOneRequestOnAHybridDataProvider:
            launchProductsListThatFetchsAllProductsInOneRequestOnAHybridDataProvider()
        case .productsListWithPagination:
            launchProductsListWithPagination()
        case .productsListWithPaginationOnAHybridDataProvider:
            launchProductsListWithPaginationOnAHybridDataProvider()
        case .popularBabyNames:
            launchPopularBabyNamesScreen()
        }
    }

    private func launchProductsListThatFetchsAllProductsInOneRequest() {
        window.rootViewController = builders.makeMainScreen()
    }

    private func launchProductsListThatFetchsAllProductsInOneRequestOnAHybridDataProvider() {
        window.rootViewController = builders.makeDummyProductsListScreenInjectingHybridDataProvider()
    }

    private func launchProductsListWithPagination() {
        window.rootViewController = builders.makeDummyProductsListScreenOnAPaginatedModel()
    }

    private func launchProductsListWithPaginationOnAHybridDataProvider() {
        window.rootViewController = builders.makeDummyProductsListScreenInjectingHybridDataProviderOnAPaginatedModel()
    }

    private func launchPopularBabyNamesScreen() {
        window.rootViewController = builders.makePopularBabyNamesScreen()
    }
}
