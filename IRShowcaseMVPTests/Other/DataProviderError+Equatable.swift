//
//  DataProviderError+Equatable.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

@testable import IRShowcaseMVP

extension DataProviderError: @retroactive Equatable {
    public static func == (lhs: DataProviderError, rhs: DataProviderError) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.invalidType, invalidType):
            return true
        case (.requestError(error: _), .requestError(error: _)):
            return true
        case (.requestHttpStatusError(httpStatusCode: let lhsHttpStatusCode, error: _), .requestHttpStatusError(httpStatusCode: let rhsHttpStatusCode, error: _)):
            return lhsHttpStatusCode == rhsHttpStatusCode
        case (.invalidHttpUrlResponse, .invalidHttpUrlResponse):
            return true
        case (.noConnectivity, .noConnectivity):
            return true
        case (.persistence(error: _), .persistence(error: _)):
            return true
        case (.parsing(error: _), .parsing(error: _)):
            return true
        case (.fetch(error: _), .fetch(error: _)):
            return true
        case (.casting, .casting):
            return true
        case (.networkingDisabled, .networkingDisabled):
            return true
        case (.noDataFromFetch, .noDataFromFetch):
            return true
        default:
            return false
        }
    }
}
