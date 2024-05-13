//
//  RootCoordinator.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 20/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation
import UIKit

protocol RootRouting {
    func start()
}

final class RootCoordinator: RootRouting {
    private enum LaunchFlow {
        case onBoarding
        case mainScreen
    }
    
    private var window: UIWindow
    private let builders: RootCoordinatorChildBuilders

    init(window w: UIWindow, builders b: RootCoordinatorChildBuilders) {
        window = w
        builders = b
    }

    func start() {
        launchMainScreen()
    }

    func launchMainScreen() {
        window.rootViewController = builders.makeMainScreen()
    }
    
    func launchOnBoarding() {
        window.rootViewController = builders.makeOnBoarding()
    }
    
    private func handleLaunchFlow(_ launchFlow: LaunchFlow) {
        switch launchFlow {
        case .mainScreen:
            launchMainScreen()
        case .onBoarding:
            launchOnBoarding()
        }
    }
}
