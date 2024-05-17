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
    func makeDummyProductsListScreenInjectingHybridDataProviders() -> UIViewController
    func makePopularBabyNamesScreen() -> UIViewController
}

struct RootCoordinatorBuilder: RootCoordinatorChildBuilders {
    func make(window: UIWindow) -> RootCoordinator {
        return RootCoordinator(window: window, builders: self)
    }
    
    func makeMainScreen() -> UIViewController {
        // Example on how to inject the PersistenceLayer and the APIService
        let view = DummyProductsScreenBuilder().make(
            localDataProvider: PersistenceLayerBuilder.make(),
            remoteDataProvider: APIServiceBuilder.make()
        )
        return UIHostingController(rootView: view)
    }
    
    // Example on how to inject the DataProviders with different configs to do the same as above
    // The presenter can be modified to use only one DataProvider with a config = localOnErrorUseRemote
    func makeDummyProductsListScreenInjectingHybridDataProviders() -> UIViewController {
        let network = APIServiceBuilder.make()
        let persistence = PersistenceLayerBuilder.make()
        let localDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: .localOnly,
            network: network,
            persistence: persistence
        )
        let remoteDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: .remoteOnly,
            network: network,
            persistence: persistence
        )
        let view = DummyProductsScreenBuilder().make(
            localDataProvider: localDataProvider,
            remoteDataProvider: remoteDataProvider
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
