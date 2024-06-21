//
//  DataProviderPublisherHandlersBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 20/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

struct DataProviderPublisherHandlersBuilder<T: Codable & Sendable> {
    let standardNetworkHandler: DataProviderPublisherHandlers<T>.NetworkHandler = { (fetchable, urlRequest) in
        let network: ((Data, URLResponse)) -> AnyPublisher<Data, DataProviderError> = { tuple in
            Future { promise in
                if let cast = tuple.1 as? HTTPURLResponse, cast.statusCode == 400 {
                    let error = NSError.error(withMessage: "DataProviderHandlers", statusCode: cast.statusCode)
                    promise(.failure(.requestError(error: error)))
                    return
                }
                promise(.success(tuple.0))
            }.eraseToAnyPublisher()
        }

        return fetchable.fetchDataPublisher(request: urlRequest).flatMap(network).eraseToAnyPublisher()
    }

    let standardNetworkParserHandler: DataProviderPublisherHandlers<T>.NetworkParserHandler = { data in
        Future { promise in
            do {
                let results = try JSONDecoder().decode(T.self, from: data)
                promise(.success(results))
            } catch {
                promise(.failure(.parsing(error: error)))
            }
        }.eraseToAnyPublisher()
    }

    let standardPersistenceSaveHandler: DataProviderPublisherHandlers<T>.PersistenceSaveHandler = { (persistenceLayer, codables) in
        Future { promise in
            persistenceLayer.persistObjects(codables) { _, error in
                if let e = error {
                    promise(.failure(DataProviderError.persistence(error: e)))
                    return
                }
                promise(.success(codables))

            }
        }.eraseToAnyPublisher()
    }

    let standardPersistenceLoadHandler: DataProviderPublisherHandlers<T>.PersistenceLoadHandler = { (persistenceLayer, resource) in
        return persistenceLayer.fetchResourcePublisher(resource).mapError({ DataProviderError.persistence(error: $0) }).eraseToAnyPublisher()
    }

    let standardPersistenceRemoveHandler: DataProviderPublisherHandlers.PersistenceRemoveHandler = { (persistenceLayer, resource) in
        return persistenceLayer.removeResourcePublisher(resource).mapError({ DataProviderError.persistence(error: $0) }).eraseToAnyPublisher()
    }

    // Disable force_cast because this we need to use it to help the compiler with the associatedType
    // swiftlint:disable force_cast
    func makeDataProviderPublisherHandlers<TP: Codable>(config: DataProviderConfiguration) -> DataProviderPublisherHandlers<TP> {
        var networkHandler: DataProviderPublisherHandlers<TP>.NetworkHandler
        var networkParserHandler: DataProviderPublisherHandlers<TP>.NetworkParserHandler
        var persistenceSaveHandler: DataProviderPublisherHandlers<TP>.PersistenceSaveHandler
        var persistenceLoadHandler: DataProviderPublisherHandlers<TP>.PersistenceLoadHandler
        var persistenceRemoveHandler: DataProviderPublisherHandlers<TP>.PersistenceRemoveHandler

        if config.persistenceEnabled {
            persistenceSaveHandler = standardPersistenceSaveHandler as! DataProviderPublisherHandlers<TP>.PersistenceSaveHandler
            persistenceLoadHandler = standardPersistenceLoadHandler as! DataProviderPublisherHandlers<TP>.PersistenceLoadHandler
            persistenceRemoveHandler = standardPersistenceRemoveHandler
        } else {
            persistenceSaveHandler = { _, _ in
                Fail(error: DataProviderError.persistence(error: PersistenceLayerError.disabled)).eraseToAnyPublisher()
            }
            persistenceLoadHandler = { _, _ in
                Fail(error: DataProviderError.persistence(error: PersistenceLayerError.disabled)).eraseToAnyPublisher()
            }
            persistenceRemoveHandler = { _, _ in
                Fail(error: DataProviderError.persistence(error: PersistenceLayerError.disabled)).eraseToAnyPublisher()
            }
        }

        if config.remoteEnabled {
            networkHandler = standardNetworkHandler
            networkParserHandler = standardNetworkParserHandler as! DataProviderPublisherHandlers<TP>.NetworkParserHandler
        } else {
            networkHandler = { _, _ in Future { promise in promise(.failure(DataProviderError.networkingDisabled)) }.eraseToAnyPublisher() }
            networkParserHandler = { _ in Future { promise in promise(.failure(DataProviderError.networkingDisabled)) }.eraseToAnyPublisher() }
        }

        return DataProviderPublisherHandlers(
            networkHandler: networkHandler,
            networkParserHandler: networkParserHandler,
            persistenceSaveHandler: persistenceSaveHandler,
            persistenceLoadHandler: persistenceLoadHandler,
            persistenceRemoveHandler: persistenceRemoveHandler
        )
    }
    // swiftlint:enable force_cast
}
