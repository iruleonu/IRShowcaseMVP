//
//  DataProviderConfiguration.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct DataProviderConfiguration {
    static let standard: DataProviderConfiguration = remoteOnErrorUseLocal

    static let localOnly: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: false, remoteFirst: false, sendMultipleValuesFromBothLayers: false)
    }()

    static let remoteOnly: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: false, remoteEnabled: true, remoteFirst: true, sendMultipleValuesFromBothLayers: false)
    }()

    static let localOnErrorUseRemote: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: false, sendMultipleValuesFromBothLayers: false)
    }()

    static let remoteOnErrorUseLocal: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: true, sendMultipleValuesFromBothLayers: false)
    }()

    static let localFirstThenRemote: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: false, sendMultipleValuesFromBothLayers: true)
    }()

    static let remoteFirstThenLocal: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: true, sendMultipleValuesFromBothLayers: true)
    }()

    let persistenceEnabled: Bool
    let remoteEnabled: Bool
    let remoteFirst: Bool
    let sendMultipleValuesFromBothLayers: Bool

    init(persistenceEnabled pe: Bool, remoteEnabled re: Bool, remoteFirst rf: Bool, sendMultipleValuesFromBothLayers smvfbl: Bool) {
        persistenceEnabled = pe
        remoteEnabled = re
        remoteFirst = rf
        sendMultipleValuesFromBothLayers = smvfbl
    }
}
