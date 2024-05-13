//
//  RootCoordinatorBuilder.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 20/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine

protocol RootCoordinatorChildBuilders {
    func makeMainScreen() -> UIViewController
    func makeOnBoarding() -> UIViewController
}

struct RootCoordinatorBuilder: RootCoordinatorChildBuilders {
    func make(window: UIWindow) -> RootCoordinator {
        return RootCoordinator(window: window, builders: self)
    }
    
    func makeMainScreen() -> UIViewController {
        let network = APIServiceBuilder.make()
        let persistence = PersistenceLayerBuilder.make()
        let dataProvider: DataProvider<[BabyNamePopularity]> = DataProviderBuilder.makeDataProvider(
            config: .remoteIfErrorUseLocal,
            network: network,
            persistence: persistence
        )
        let view = RandomNameSelectorScreenBuilder().make(dataProvider: dataProvider)
        return UIHostingController(rootView: view)
    }
    
    func makeOnBoarding() -> UIViewController {
        // TODO: on boarding
        let network = APIServiceBuilder.make()
        let persistence = PersistenceLayerBuilder.make()
        let dataProvider: DataProvider<[BabyNamePopularity]> = DataProviderBuilder.makeDataProvider(
            config: .remoteIfErrorUseLocal,
            network: network,
            persistence: persistence
        )
        let view = RandomNameSelectorScreenBuilder().make(dataProvider: dataProvider)
        return UIHostingController(rootView: view)
    }
}
