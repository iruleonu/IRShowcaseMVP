//
//  DataProviderHandlersBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

struct DataProviderHandlersBuilder<T: Codable & Sendable> {
    let standardNetworkHandler: DataProviderHandlers<T>.NetworkHandler = { (fetchable, urlRequest) in
        let values = try await fetchable.fetchData(request: urlRequest)

        // Check for the 400 status code
        if let cast = values.1 as? HTTPURLResponse, cast.statusCode == 400 {
            let error = NSError.error(withMessage: "DataProviderHandlers", statusCode: cast.statusCode)
            throw DataProviderError.requestError(error: error)
        }

        return values.0
    }
    let standardNetworkParserHandler: DataProviderHandlers<T>.NetworkParserHandler = { data in
        do {
            let results = try JSONDecoder().decode(T.self, from: data)
            return results
        } catch {
            throw DataProviderError.parsing(error: error)
        }
    }
    let standardPersistenceSaveHandler: DataProviderHandlers<T>.PersistenceSaveHandler = { (persistenceLayer, codables) in
        try await withCheckedThrowingContinuation { continuation in
            persistenceLayer.persistObjects(codables) { _, error in
                if let e = error {
                    continuation.resume(throwing: DataProviderError.persistence(error: e))
                } else {
                    continuation.resume(returning: codables)
                }
            }
        }
    }
    let standardPersistenceLoadHandler: DataProviderHandlers<T>.PersistenceLoadHandler = { (persistenceLayer, resource) in
        do {
            return try await persistenceLayer.fetchResource(resource)
        } catch {
            throw DataProviderError.persistence(error: error)
        }
    }
    let standardPersistenceRemoveHandler: DataProviderHandlers.PersistenceRemoveHandler = { (persistenceLayer, resource) in
        do {
            return try await persistenceLayer.removeResource(resource)
        } catch {
            throw DataProviderError.persistence(error: error)
        }
    }

    // Disable force_cast because this we need to use it to help the compiler with the associatedType
    // swiftlint:disable force_cast
    func makeDataProviderHandlers<TP: Codable>(config: DataProviderConfiguration) -> DataProviderHandlers<TP> {
        var networkHandler: DataProviderHandlers<TP>.NetworkHandler
        var networkParserHandler: DataProviderHandlers<TP>.NetworkParserHandler
        var persistenceSaveHandler: DataProviderHandlers<TP>.PersistenceSaveHandler
        var persistenceLoadHandler: DataProviderHandlers<TP>.PersistenceLoadHandler
        var persistenceRemoveHandler: DataProviderHandlers<TP>.PersistenceRemoveHandler

        if config.persistenceEnabled {
            persistenceSaveHandler = standardPersistenceSaveHandler as! DataProviderHandlers<TP>.PersistenceSaveHandler
            persistenceLoadHandler = standardPersistenceLoadHandler as! DataProviderHandlers<TP>.PersistenceLoadHandler
            persistenceRemoveHandler = standardPersistenceRemoveHandler
        } else {
            persistenceSaveHandler = { @Sendable _, _ in
                throw PersistenceLayerError.disabled
            }
            persistenceLoadHandler = { @Sendable _, _ in
                throw PersistenceLayerError.disabled
            }
            persistenceRemoveHandler = { @Sendable _, _ in
                throw PersistenceLayerError.disabled
            }
        }

        if config.remoteEnabled {
            networkHandler = standardNetworkHandler
            networkParserHandler = standardNetworkParserHandler as! DataProviderHandlers<TP>.NetworkParserHandler
        } else {
            networkHandler = { @Sendable _, _ in
                throw DataProviderError.networkingDisabled
            }
            networkParserHandler = { @Sendable _ in
                throw DataProviderError.networkingDisabled
            }
        }

        return DataProviderHandlers(networkHandler: networkHandler,
                                    networkParserHandler: networkParserHandler,
                                    persistenceSaveHandler: persistenceSaveHandler,
                                    persistenceLoadHandler: persistenceLoadHandler,
                                    persistenceRemoveHandler: persistenceRemoveHandler)
    }
    // swiftlint:enable force_cast
}
