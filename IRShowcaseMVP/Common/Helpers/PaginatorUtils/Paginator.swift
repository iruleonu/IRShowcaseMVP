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

final class PaginatorSinglePublisher<Result> {
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

final class PaginatorPublisher<Result> {
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

final class PaginatorSingle<Result> {
    private var page: Int
    private var result: Result?
    private let useCase: (_ page: Int) async throws -> (data: Result, isLastPage: Bool)

    init(useCase: @escaping @Sendable ((_ page: Int) async throws -> (data: Result, isLastPage: Bool))) {
        page = 0
        self.useCase = useCase
    }

    func resetPaginationAndFetchInitialPage() async throws -> (data: Result, isLastPage: Bool) {
        let initialPage = 0
        let callUseCase = try await useCase(initialPage)
        self.page = initialPage
        self.result = callUseCase.data
        return callUseCase
    }

    func fetchFollowingPage() async throws -> (data: Result, isLastPage: Bool) {
        let newPage = page + 1
        let callUseCase = try await useCase(newPage)
        self.result = callUseCase.data
        self.page = newPage
        return (data: callUseCase.data, isLastPage: callUseCase.isLastPage)
    }
}

final class Paginator<Result> {
    private var page: Int
    private var allResults: [Result] = []
    private let useCase: (_ page: Int) async throws -> (data: [Result], isLastPage: Bool)

    init(useCase: @escaping (_ page: Int) async throws -> (data: [Result], isLastPage: Bool)) {
        page = 0
        self.useCase = useCase
    }

    func resetPagination() async throws -> (data: [Result], isLastPage: Bool) {
        let initialPage = 0
        let callUseCase = try await useCase(initialPage)
        self.page = initialPage
        self.allResults = callUseCase.data
        return callUseCase
    }

    func fetchFollowingPage() async throws -> (data: [Result], isLastPage: Bool) {
        let newPage = page + 1
        let callUseCase = try await useCase(newPage)
        let newResults = allResults + callUseCase.data
        allResults = newResults
        page = newPage
        return (data: newResults, isLastPage: callUseCase.isLastPage)
    }
}
