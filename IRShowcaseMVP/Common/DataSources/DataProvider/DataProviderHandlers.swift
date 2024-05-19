//
//  DataProviderHandlers.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

struct DataProviderHandlers<T: Codable> {
    typealias NetworkHandler = (URLRequestFetchable, URLRequest) -> AnyPublisher<Data, DataProviderError>
    typealias NetworkParserHandler = (Data) -> AnyPublisher<T, DataProviderError>
    typealias PersistenceSaveHandler = (PersistenceLayerSave, T) -> AnyPublisher<T, DataProviderError>
    typealias PersistenceLoadHandler = (PersistenceLayerLoad, Resource) -> AnyPublisher<T, DataProviderError>
    typealias PersistenceRemoveHandler = (PersistenceLayerRemove, Resource) -> AnyPublisher<Bool, DataProviderError>

    let networkHandler: NetworkHandler
    let networkParserHandler: NetworkParserHandler
    let persistenceSaveHandler: PersistenceSaveHandler
    let persistenceLoadHandler: PersistenceLoadHandler
    let persistenceRemoveHandler: PersistenceRemoveHandler

    init(networkHandler nh: @escaping NetworkHandler = { (_, _) in Empty().eraseToAnyPublisher() },
         networkParserHandler nph: @escaping NetworkParserHandler = { _ in Empty().eraseToAnyPublisher() },
         persistenceSaveHandler psh: @escaping PersistenceSaveHandler = { (_, _) in Empty().eraseToAnyPublisher() },
         persistenceLoadHandler plh: @escaping PersistenceLoadHandler = { (_, _) in Empty().eraseToAnyPublisher() },
         persistenceRemoveHandler prh: @escaping PersistenceRemoveHandler = { (_, _) in Empty().eraseToAnyPublisher() }) {
        networkHandler = nh
        networkParserHandler = nph
        persistenceSaveHandler = psh
        persistenceLoadHandler = plh
        persistenceRemoveHandler = prh
    }
}
