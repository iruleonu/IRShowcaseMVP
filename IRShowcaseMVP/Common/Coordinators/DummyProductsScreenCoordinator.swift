//
//  DummyProductsScreenCoordinator.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import UIKit

// sourcery: AutoMockable
protocol DummyProductsScreenRouting {
    func makeDummyProductDetailsView(dummyProduct: DummyProduct) -> DummyProductDetailsView
}

final class DummyProductsScreenCoordinator: DummyProductsScreenRouting {
    private let builders: DummyProductsScreenChildBuilders

    init(builders b: DummyProductsScreenChildBuilders) {
        builders = b
    }

    func makeDummyProductDetailsView(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        return builders.makeDummyProductDetailsView(dummyProduct: dummyProduct)
    }
}
