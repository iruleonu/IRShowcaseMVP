//
//  DummyProductDetailsScreenBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI

// Actions available from built childs
enum DummyProductDetailsScreenAction {
    // Empty
}

protocol DummyProductDetailsScreenChildBuilders {
    // Empty
}

struct DummyProductDetailsScreenBuilder {
    func make(dummyProduct: DummyProduct) -> DummyProductDetailsView {
        let coordinator = DummyProductDetailsScreenCoordinator(builders: self)
        let viewModel = DummyProductDetailsViewModelImpl(routing: coordinator, dummyProduct: dummyProduct)
        return DummyProductDetailsView(viewModel: viewModel)
    }
}

extension DummyProductDetailsScreenBuilder: DummyProductDetailsScreenChildBuilders {
    
}
