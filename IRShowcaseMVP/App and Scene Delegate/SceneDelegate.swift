//
//  SceneDelegate.swift
//  IRCV
//
//  Created by Nuno Salvador on 13/06/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var rootCoordinator: RootCoordinator?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard ProcessInfo.processInfo.isPreview == false else {
            return
        }
        guard ProcessInfo.processInfo.isRunningTests == false else {
            return
        }
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        let deepLinkUrl = connectionOptions.userActivities
            .first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb })?
            .webpageURL ?? connectionOptions.urlContexts.map({ $0.url }).first

        let launchFlow: RootCoordinator.LaunchFlow = .productsListThatFetchsAllProductsInOneRequest
        // let launchFlow: RootCoordinator.LaunchFlow = .productsListThatFetchsAllProductsInOneRequestOnAHybridDataProvider
        // let launchFlow: RootCoordinator.LaunchFlow = .productsListWithPagination
        // let launchFlow: RootCoordinator.LaunchFlow = .productsListWithPaginationOnAHybridDataProvider
        // let launchFlow: RootCoordinator.LaunchFlow = .popularBabyNames

        initializeAppCoordinatorAndWindow(
            windowScene: windowScene,
            launchFlow: launchFlow,
            handleDeepLink: { [weak self] in
                guard let url = deepLinkUrl else { return }
                // Handle launch deep link after splash screen:
                self?.handleDeepLink(url: url)
            }
        )
    }
}

private extension SceneDelegate {
    func initializeAppCoordinatorAndWindow(
        windowScene: UIWindowScene,
        launchFlow: RootCoordinator.LaunchFlow,
        handleDeepLink: @escaping () -> Void
    ) {
        let window = UIWindow(windowScene: windowScene)
        window.makeKeyAndVisible()
        self.rootCoordinator = RootCoordinatorBuilder().make(
            window: window,
            launchFlow: launchFlow
        )
        self.rootCoordinator?.start()
    }

    func handleDeepLink(url: URL) {
        // do nothing
    }
}
