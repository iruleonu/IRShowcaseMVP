//
//  DataProviderErrors.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 21/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation

enum DataProviderError: Error {
    case unknown
    case invalidType
    case requestError(error: Error)
    case requestHttpStatusError(httpStatusCode: Int, error: Error?)
    case invalidHttpUrlResponse
    case noConnectivity
    case persistence(error: Error)
    case parsing(error: Error)
    case fetch(error: Error)
    case casting
    case networkingDisabled
    case noDataFromFetch

    var errorDescription: String {
        switch self {
        case .parsing:
            return "Parsing"
        case .requestHttpStatusError:
            return "Request error"
        case .noConnectivity:
            return "No network"
        case .persistence:
            return "Persistence error"
        default:
            return "Unknown error"
        }
    }
}
