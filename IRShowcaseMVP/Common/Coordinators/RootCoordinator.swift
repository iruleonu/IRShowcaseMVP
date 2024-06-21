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
        case mainScreen
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
        handleLaunchFlow(.mainScreen)
    }

    @MainActor 
    func launchMainScreen() {
        window.rootViewController = builders.makeMainScreen()
        //window.rootViewController = builders.makeDummyProductsListScreenInjectingHybridDataProvider()
        //window.rootViewController = builders.makeDummyProductsListScreenOnAPaginatedModel()
        //window.rootViewController = builders.makeDummyProductsListScreenInjectingHybridDataProviderOnAPaginatedModel()
    }
    
    @MainActor 
    func launchPopularBabyNamesScreen() {
        window.rootViewController = builders.makePopularBabyNamesScreen()
    }
    
    @MainActor 
    private func handleLaunchFlow(_ launchFlow: LaunchFlow) {
        switch launchFlow {
        case .mainScreen:
            launchMainScreen()
        case .popularBabyNames:
            launchPopularBabyNamesScreen()
        }
    }
}
