//
//  DataProviderHandlersBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

struct DataProviderHandlersBuilder<T: Codable> {
    let standardNetworkHandler: DataProviderHandlers<T>.NetworkHandler = { (fetchable, urlRequest) in
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
        return fetchable.fetchData(request: urlRequest).flatMap(network).eraseToAnyPublisher()
    }
    let standardNetworkParserHandler: DataProviderHandlers<T>.NetworkParserHandler = { data in
        Future { promise in
            do {
                let results = try JSONDecoder().decode(T.self, from: data)
                promise(.success(results))
            } catch {
                promise(.failure(.parsing(error: error)))
            }
        }.eraseToAnyPublisher()
    }
    let standardPersistenceSaveHandler: DataProviderHandlers<T>.PersistenceSaveHandler = { (persistenceLayer, codables) in
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
    let standardPersistenceLoadHandler: DataProviderHandlers<T>.PersistenceLoadHandler = { (persistenceLayer, resource) in
        return persistenceLayer.fetchResource(resource).mapError({ DataProviderError.persistence(error: $0) }).eraseToAnyPublisher()
    }
    let standardPersistenceRemoveHandler: DataProviderHandlers.PersistenceRemoveHandler = { (persistenceLayer, resource) in
        return persistenceLayer.removeResource(resource).mapError({ DataProviderError.persistence(error: $0) }).eraseToAnyPublisher()
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
            persistenceSaveHandler = { _, _ in
                Future { promise in promise(.failure(DataProviderError.persistence(error: PersistenceLayerError.disabled))) }.eraseToAnyPublisher()
            }
            persistenceLoadHandler = { _, _ in
                Future { promise in promise(.failure(DataProviderError.persistence(error: PersistenceLayerError.disabled))) }.eraseToAnyPublisher()
            }
            persistenceRemoveHandler = { _, _ in
                Future { promise in promise(.failure(DataProviderError.persistence(error: PersistenceLayerError.disabled))) }.eraseToAnyPublisher()
            }
        }

        if config.remoteEnabled {
            networkHandler = standardNetworkHandler
            networkParserHandler = standardNetworkParserHandler as! DataProviderHandlers<TP>.NetworkParserHandler
        } else {
            networkHandler = { _, _ in Future { promise in promise(.failure(DataProviderError.networkingDisabled)) }.eraseToAnyPublisher() }
            networkParserHandler = { _ in Future { promise in promise(.failure(DataProviderError.networkingDisabled)) }.eraseToAnyPublisher() }
        }

        return DataProviderHandlers(networkHandler: networkHandler,
                                    networkParserHandler: networkParserHandler,
                                    persistenceSaveHandler: persistenceSaveHandler,
                                    persistenceLoadHandler: persistenceLoadHandler,
                                    persistenceRemoveHandler: persistenceRemoveHandler)
    }
    // swiftlint:enable force_cast
}
