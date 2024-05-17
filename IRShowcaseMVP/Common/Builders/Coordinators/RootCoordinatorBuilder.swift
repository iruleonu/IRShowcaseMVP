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
    func makeDummyProductsListScreenInjectingHybridDataProvider() -> UIViewController
    func makePopularBabyNamesScreen() -> UIViewController
}

struct RootCoordinatorBuilder: RootCoordinatorChildBuilders {
    func make(window: UIWindow) -> RootCoordinator {
        return RootCoordinator(window: window, builders: self)
    }
    
    // Example on how to inject the PersistenceLayer and the APIService
    func makeMainScreen() -> UIViewController {
        let view = DummyProductsScreenBuilder().make(
            localDataProvider: PersistenceLayerBuilder.make(),
            remoteDataProvider: APIServiceBuilder.make()
        )
        return UIHostingController(rootView: view)
    }
    
    // Example on how to inject a hybrid DataProvider with different configs to do the same as above
    // where it injects two different providers
    func makeDummyProductsListScreenInjectingHybridDataProvider() -> UIViewController {
        let hybridDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: .localOnErrorUseRemote,
            network: APIServiceBuilder.make(),
            persistence: PersistenceLayerBuilder.make()
        )
        let view = DummyProductsScreenBuilder().make(
            dataProvider: hybridDataProvider
        )
        return UIHostingController(rootView: view)
    }

    // Hybrid DataProvider that supports all the data provider configs.
    // Right now is set to .localOnly
    func makePopularBabyNamesScreen() -> UIViewController {
        let network = APIServiceBuilder.make()
        let persistence = PersistenceLayerBuilder.make()
        let dataProvider: DataProvider<BabyNamePopularityDataContainer> = DataProviderBuilder.makeDataProvider(
            config: .localOnly,
            network: network,
            persistence: persistence
        )
        let view = RandomNameSelectorScreenBuilder().make(dataProvider: dataProvider)
        return UIHostingController(rootView: view)
    }
}
