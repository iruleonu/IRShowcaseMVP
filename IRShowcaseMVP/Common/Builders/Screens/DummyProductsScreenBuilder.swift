//
//  DummyProductsScreenBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI

// Actions available from childs built from PostsListChildBuilders
enum DummyProductsScreenAction {
    // Empty
}

protocol DummyProductsScreenChildBuilders {
    func makeDummyProductDetailsView(dummyProduct: DummyProduct) -> DummyProductDetailsView
}

struct DummyProductsScreenBuilder {
    func make(
        localDataProvider: DummyProductsLocalDataProvider,
        remoteDataProvider: FetchDummyProductsProtocol
    ) -> DummyProductsView {
        let coordinator = DummyProductsScreenCoordinator(builders: self)
        let viewModel = DummyProductsViewModelImpl(
            routing: coordinator,
            localDataProvider: localDataProvider,
            remoteDataProvider: remoteDataProvider
        )
        return DummyProductsView(viewModel: viewModel)
    }

    func make(dataProvider: DummyProductsLocalDataProvider) -> DummyProductsView {
        let coordinator = DummyProductsScreenCoordinator(builders: self)
        let viewModel = DummyProductsWithHybridDataProviderViewModelImpl(
            routing: coordinator,
            dataProvider: dataProvider
        )
        return DummyProductsView(viewModel: viewModel)
    }

    func makeUsingPaginatedViewModel(
        localDataProvider: DummyProductsLocalDataProvider,
        remoteDataProvider: FetchDummyProductsProtocol,
        paginationSize: Int
    ) -> DummyProductsView {
        let coordinator = DummyProductsScreenCoordinator(builders: self)
        let viewModel = DummyProductsWithPaginationViewModelImpl(
            routing: coordinator,
            localDataProvider: localDataProvider,
            remoteDataProvider: remoteDataProvider, 
            paginationSize: paginationSize
        )
        return DummyProductsView(viewModel: viewModel)
    }

    func makeUsingPaginatedViewModel(
        hybridDataProvider: DummyProductsLocalDataProvider,
        paginationSize: Int
    ) -> DummyProductsView {
        let coordinator = DummyProductsScreenCoordinator(builders: self)
        let viewModel = DummyProductsWithPaginationAndHybridDataProviderViewModelImpl(
            routing: coordinator,
            dataProvider: hybridDataProvider,
            paginationSize: paginationSize
        )
        return DummyProductsView(viewModel: viewModel)
    }
}

extension DummyProductsScreenBuilder: DummyProductsScreenChildBuilders {
    func makeDummyProductDetailsView(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        return DummyProductDetailsScreenBuilder().make(dummyProduct: dummyProduct)
    }
}
