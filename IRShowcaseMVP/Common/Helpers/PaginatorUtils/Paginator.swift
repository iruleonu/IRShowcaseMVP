//
//  Paginator.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

enum PageFetchType {
    case initialPage
    case nextPage
}

final class PaginatorSingle<Result> {
    private var page: Int
    private var result: Result?
    private let useCase: (_ page: Int) -> AnyPublisher<(data: Result, isLastPage: Bool), Error>

    init(useCase: @escaping ((_ page: Int) -> AnyPublisher<(data: Result, isLastPage: Bool), Error>)) {
        page = 0
        self.useCase = useCase
    }

    func resetPaginationAndFetchInitialPage() -> AnyPublisher<(data: Result, isLastPage: Bool), Error> {
        let initialPage = 0
        return useCase(initialPage)
            .handleEvents(receiveOutput: { [weak self] in
                self?.page = initialPage
                self?.result = $0.data
            })
            .eraseToAnyPublisher()
    }

    func fetchFollowingPage() -> AnyPublisher<(data: Result, isLastPage: Bool), Error> {
        let newPage = page + 1
        return useCase(newPage)
            .map({ [weak self] in
                self?.result = $0.data
                return (data: $0.data, isLastPage: $0.isLastPage)
            })
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.page = newPage
            })
            .eraseToAnyPublisher()
    }
}

final class Paginator<Result> {
    private var page: Int
    private var allResults: [Result] = []
    private let useCase: ( (_ page: Int) -> AnyPublisher<(data: [Result], isLastPage: Bool), Error>)

    init(useCase: @escaping ( (_ page: Int) -> AnyPublisher<(data: [Result], isLastPage: Bool), Error>)) {
        page = 0
        self.useCase = useCase
    }

    func resetPagination() -> AnyPublisher<(data: [Result], isLastPage: Bool), Error> {
        let initialPage = 0
        return useCase(initialPage)
            .handleEvents(receiveOutput: { [weak self] in
                self?.page = initialPage
                self?.allResults = $0.data
            })
            .eraseToAnyPublisher()
    }

    func fetchFollowingPage() -> AnyPublisher<(data: [Result], isLastPage: Bool), Error> {
        let newPage = page + 1
        return useCase(newPage)
            .map({ [weak self] in
                let newResults = (self?.allResults ?? []) + $0.data
                self?.allResults = newResults
                return (data: newResults, isLastPage: $0.isLastPage)
            })
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.page = newPage
            })
            .eraseToAnyPublisher()
    }
}
