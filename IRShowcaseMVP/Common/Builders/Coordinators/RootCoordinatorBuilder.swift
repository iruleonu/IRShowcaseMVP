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

@MainActor 
protocol RootCoordinatorChildBuilders {
    // Shows a dummy product list screen with a viewModel that firstly fetchs all the products and then sends them to the view
    func makeMainScreen() -> UIViewController

    // Shows a dummy product list screen with a viewModel that firstly fetchs all the products and then sends them to the view using a hybrid/unified data provider
    func makeDummyProductsListScreenInjectingHybridDataProvider() -> UIViewController

    // Shows a dummy product list screen with a viewModel that fetchs the next products when the user is almost at the end of the list
    func makeDummyProductsListScreenOnAPaginatedModel() -> UIViewController

    // Shows a dummy product list screen with a viewModel that fetchs the next products when the user is almost at the end of the list using a hybrid/unified data provider
    func makeDummyProductsListScreenInjectingHybridDataProviderOnAPaginatedModel() -> UIViewController

    // Shows a screen with popular baby names
    func makePopularBabyNamesScreen() -> UIViewController
}

struct RootCoordinatorBuilder: RootCoordinatorChildBuilders {
    func make(window: UIWindow) -> RootCoordinator {
        return RootCoordinator(window: window, builders: self)
    }

    /// Shows a product list screen with a viewModel that firstly fetchs all the products and then sends them to the view
    /// - Note: Also serves as an example on how to inject the PersistenceLayer and the APIService
    /// - Returns: UIViewController to be used on the rootViewController
    func makeMainScreen() -> UIViewController {
        let view = DummyProductsScreenBuilder().make(
            localDataProvider: PersistenceLayerBuilder.make(),
            remoteDataProvider: APIServiceBuilder.make()
        )
        return UIHostingController(rootView: view)
    }

    /// Shows a product list screen with a viewModel that firstly fetchs all the products and then sends them to the view (using a hybrid/unified data provider)
    /// - Note: Also serves as an example on how to inject a hybrid DataProvider with different configs to do the same as above where it injects two different providers
    /// - Returns: UIViewController to be used on the rootViewController
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

    /// Shows a product list screen with a viewModel that fetchs the next products when the user is almost at the end of the list
    /// - Note: Also serves as an example on how to inject the PersistenceLayer and the APIService
    /// - Returns: UIViewController to be used on the rootViewController
    func makeDummyProductsListScreenOnAPaginatedModel() -> UIViewController  {
        let view = DummyProductsScreenBuilder().makeUsingPaginatedViewModel(
            localDataProvider: PersistenceLayerBuilder.make(),
            remoteDataProvider: APIServiceBuilder.make(),
            paginationSize: Constants.DummyProductsAPIPageSize
        )
        return UIHostingController(rootView: view)
    }

    /// Shows a product list screen with a viewModel that fetchs the next products when the user is almost at the end of the list (using a hybrid/unified data provider)
    /// - Note: Also serves as an example on how to inject a hybrid DataProvider with different configs to do the same as above where it injects two different providers
    /// - Returns: UIViewController to be used on the rootViewController
    func makeDummyProductsListScreenInjectingHybridDataProviderOnAPaginatedModel() -> UIViewController {
        let hybridDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: .localOnErrorUseRemote,
            network: APIServiceBuilder.make(),
            persistence: PersistenceLayerBuilder.make()
        )
        let view = DummyProductsScreenBuilder().makeUsingPaginatedViewModel(
            hybridDataProvider: hybridDataProvider, 
            paginationSize: Constants.DummyProductsAPIPageSize
        )
        return UIHostingController(rootView: view)
    }

    /// Shows a screen with popular baby names
    /// - Returns: UIViewController to be used on the rootViewController
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
