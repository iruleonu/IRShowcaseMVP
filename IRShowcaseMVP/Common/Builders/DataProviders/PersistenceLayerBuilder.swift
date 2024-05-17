//
//  PersistenceLayerBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct PersistenceLayerBuilder {
    static func make() -> PersistenceLayerImpl {
        return PersistenceLayerImpl()
    }
}
