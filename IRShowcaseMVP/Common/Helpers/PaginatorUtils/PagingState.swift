//
//  PagingState.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

enum PagingState {
    case unknown
    case loadingFirstPage
    case loadingNextPage
    case loaded
    case noMorePagesToLoad
    case error
}

extension PagingState {
    var isFetching: Bool {
        return self == .loadingNextPage || self == .loadingNextPage
    }
}
