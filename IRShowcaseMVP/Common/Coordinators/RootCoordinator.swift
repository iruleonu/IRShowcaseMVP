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
    private enum LaunchFlow {
        case productsListThatFetchsAllProductsInOneRequest
        case productsListThatFetchsAllProductsInOneRequestOnAHybridDataProvider
        case productsListWithPagination
        case productsListWithPaginationOnAHybridDataProvider
        case popularBabyNames
    }
    
    private var window: UIWindow
    private let builders: RootCoordinatorChildBuilders

    init(window w: UIWindow, builders b: RootCoordinatorChildBuilders) {
        window = w
        builders = b
    }

    @MainActor 
    func start() {
        handleLaunchFlow(.productsListThatFetchsAllProductsInOneRequest)
    }

    @MainActor
    func launchProductsListThatFetchsAllProductsInOneRequest() {
        window.rootViewController = builders.makeMainScreen()
    }

    @MainActor
    func launchProductsListThatFetchsAllProductsInOneRequestOnAHybridDataProvider() {
        window.rootViewController = builders.makeDummyProductsListScreenInjectingHybridDataProvider()
    }

    @MainActor
    func launchProductsListWithPagination() {
        window.rootViewController = builders.makeDummyProductsListScreenOnAPaginatedModel()
    }

    @MainActor
    func launchProductsListWithPaginationOnAHybridDataProvider() {
        window.rootViewController = builders.makeDummyProductsListScreenInjectingHybridDataProviderOnAPaginatedModel()
    }

    @MainActor 
    func launchPopularBabyNamesScreen() {
        window.rootViewController = builders.makePopularBabyNamesScreen()
    }
    
    @MainActor 
    private func handleLaunchFlow(_ launchFlow: LaunchFlow) {
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
}
