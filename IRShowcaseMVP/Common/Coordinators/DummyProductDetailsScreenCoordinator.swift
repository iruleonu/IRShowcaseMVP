//
//  DummyProductDetailsScreenCoordinator.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import UIKit

// sourcery: AutoMockable
protocol DummyProductDetailsScreenRouting {

}

final class DummyProductDetailsScreenCoordinator: DummyProductDetailsScreenRouting {
    private let builders: DummyProductDetailsScreenChildBuilders

    init(builders b: DummyProductDetailsScreenChildBuilders) {
        builders = b
    }
}
