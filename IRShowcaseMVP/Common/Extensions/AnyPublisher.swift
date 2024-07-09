//
//  AnyPublisher.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Combine

enum AnyPublisherAsyncError: Error {
    case finishedWithoutValue
}

@globalActor
struct AnyPublisherCombineToAsyncActor {
    actor AnyPublisherCombineToAsyncActorType { }

    static let shared: AnyPublisherCombineToAsyncActorType = AnyPublisherCombineToAsyncActorType()
}

extension AnyPublisher {
    @AnyPublisherCombineToAsyncActor
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            var finishedWithoutValue = true
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        if finishedWithoutValue {
                            continuation.resume(throwing: AnyPublisherAsyncError.finishedWithoutValue)
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    Task {
                        finishedWithoutValue = false
                        continuation.resume(returning: value)
                        cancellable?.cancel()
                    }
                }
        }
    }
}
