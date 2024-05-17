//
//  NSObject.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 21/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation

extension NSObject {
    public static func configurationValue(for configKey: String) -> String? {
        return Bundle.main.infoDictionary?[configKey] as? String
    }
}

extension NSObject {
    @objc public static var APIBaseUrl: String? {
        guard NSClassFromString("XCTestCase") == nil else { return nil }
        return configurationValue(for: "APIBaseURL")
    }

    @objc public static var APIBabyNamePopularityBASEURL: String? {
        guard NSClassFromString("XCTestCase") == nil else { return nil }
        return configurationValue(for: "APIBabyNamePopularityBASEURL")
    }

    @objc public static var APIAuthBearerKey: String? {
        guard NSClassFromString("XCTestCase") == nil else { return nil }
        return configurationValue(for: "APIAuthBearerKey")
    }

    @objc public static var APIUserAgent: String? {
        guard NSClassFromString("XCTestCase") == nil else { return nil }
        return configurationValue(for: "APIUserAgent")
    }
}
