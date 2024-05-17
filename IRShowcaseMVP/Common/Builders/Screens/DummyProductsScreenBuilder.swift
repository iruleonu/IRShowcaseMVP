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
        let presenter = DummyProductsViewPresenterImpl(
            routing: coordinator,
            localDataProvider: localDataProvider,
            remoteDataProvider: remoteDataProvider
        )
        return DummyProductsView(presenter: presenter)
    }
}

extension DummyProductsScreenBuilder: DummyProductsScreenChildBuilders {
    func makeDummyProductDetailsView(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        return DummyProductDetailsScreenBuilder().make(dummyProduct: dummyProduct)
    }
}
