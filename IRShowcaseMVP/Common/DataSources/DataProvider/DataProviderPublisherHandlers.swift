//
//  DataProviderPublisherHandlers.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

struct DataProviderPublisherHandlers<T: Codable & Sendable>: Sendable {
    typealias NetworkHandler = @Sendable (URLRequestFetchable, URLRequest) -> AnyPublisher<Data, DataProviderError>
    typealias NetworkParserHandler = @Sendable (Data) -> AnyPublisher<T, DataProviderError>
    typealias PersistenceSaveHandler = @Sendable (PersistenceLayerSave, T) -> AnyPublisher<T, DataProviderError>
    typealias PersistenceLoadHandler = @Sendable (PersistenceLayerLoad, Resource) -> AnyPublisher<T, DataProviderError>
    typealias PersistenceRemoveHandler = @Sendable (PersistenceLayerRemove, Resource) -> AnyPublisher<Bool, DataProviderError>

    let networkHandler: NetworkHandler
    let networkParserHandler: NetworkParserHandler
    let persistenceSaveHandler: PersistenceSaveHandler
    let persistenceLoadHandler: PersistenceLoadHandler
    let persistenceRemoveHandler: PersistenceRemoveHandler

    init(
        networkHandler nh: @escaping NetworkHandler = { (_, _) in Empty().eraseToAnyPublisher() },
        networkParserHandler nph: @escaping NetworkParserHandler = { _ in Empty().eraseToAnyPublisher() },
        persistenceSaveHandler psh: @escaping PersistenceSaveHandler = { (_, _) in Empty().eraseToAnyPublisher() },
        persistenceLoadHandler plh: @escaping PersistenceLoadHandler = { (_, _) in Empty().eraseToAnyPublisher() },
        persistenceRemoveHandler prh: @escaping PersistenceRemoveHandler = { (_, _) in Empty().eraseToAnyPublisher() }
    ) {
        networkHandler = nh
        networkParserHandler = nph
        persistenceSaveHandler = psh
        persistenceLoadHandler = plh
        persistenceRemoveHandler = prh
    }
}
