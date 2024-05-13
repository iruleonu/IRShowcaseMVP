//
//  Foundation.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

extension ProcessInfo {
    var isPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}
