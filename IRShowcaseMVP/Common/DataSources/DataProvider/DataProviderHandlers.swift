//
//  DataProviderHandlers.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 19/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct DataProviderHandlers<T: Codable & Sendable>: Sendable {
    typealias NetworkHandler = @Sendable (URLRequestFetchable, URLRequest) async throws -> Data
    typealias NetworkParserHandler = @Sendable (Data) async throws -> T
    typealias PersistenceSaveHandler = @Sendable (PersistenceLayerSave, T) async throws -> T
    typealias PersistenceLoadHandler = @Sendable (PersistenceLayerLoad, Resource) async throws -> T
    typealias PersistenceRemoveHandler = @Sendable (PersistenceLayerRemove, Resource) async throws -> Bool

    let networkHandler: NetworkHandler
    let networkParserHandler: NetworkParserHandler
    let persistenceSaveHandler: PersistenceSaveHandler
    let persistenceLoadHandler: PersistenceLoadHandler
    let persistenceRemoveHandler: PersistenceRemoveHandler

    init(
        networkHandler nh: @escaping NetworkHandler,
        networkParserHandler nph: @escaping NetworkParserHandler,
        persistenceSaveHandler psh: @escaping PersistenceSaveHandler,
        persistenceLoadHandler plh: @escaping PersistenceLoadHandler,
        persistenceRemoveHandler prh: @escaping PersistenceRemoveHandler
    ) {
        networkHandler = nh
        networkParserHandler = nph
        persistenceSaveHandler = psh
        persistenceLoadHandler = plh
        persistenceRemoveHandler = prh
    }
}

