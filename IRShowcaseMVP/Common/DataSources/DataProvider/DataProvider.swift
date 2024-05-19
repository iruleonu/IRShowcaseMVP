//
//  DataProvider.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 10/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

typealias DataProviderNetworkProtocol = APIURLRequestProtocol & URLRequestFetchable
typealias DataProviderPersistenceProtocol = PersistenceLayerLoad & PersistenceLayerSave & PersistenceLayerRemove

enum DataProviderSource: String {
    case local
    case remote
}

enum DataProviderFetchType {
    case config // defaults to the used data provider configuration
    case local
    case remote
}

// sourcery: AutoMockable
// sourcery: associatedtype = "TP: Codable"
protocol DataProviderProtocol {
    associatedtype TP: Codable
    var config: DataProviderConfiguration { get }
    var network: DataProviderNetworkProtocol { get }
    var persistence: DataProviderPersistenceProtocol { get }
    var handlers: DataProviderHandlers<TP> { get }
    func fetchStuff(resource: Resource) -> AnyPublisher<(TP, DataProviderSource), DataProviderError>
    func fetchStuff(resource: Resource, explicitFetchType: DataProviderFetchType) -> AnyPublisher<(TP, DataProviderSource), DataProviderError>
    func fetchStuff(
        resource: Resource,
        persistenceLoadProducer: AnyPublisher<(TP, DataProviderSource), DataProviderError>?,
        remoteProducer: AnyPublisher<(TP, DataProviderSource), DataProviderError>?,
        fetchType: DataProviderFetchType
    ) -> AnyPublisher<(TP, DataProviderSource), DataProviderError>
}

struct DataProvider<Type: Codable>: DataProviderProtocol {
    typealias T = Type
    let config: DataProviderConfiguration
    let network: DataProviderNetworkProtocol
    let persistence: DataProviderPersistenceProtocol
    let handlers: DataProviderHandlers<T>

    init(config c: DataProviderConfiguration, network n: DataProviderNetworkProtocol, persistence p: DataProviderPersistenceProtocol, handlers h: DataProviderHandlers<T>) {
        config = c
        network = n
        persistence = p
        handlers = h
    }

    func fetchStuff(resource: Resource) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        return fetchStuff(resource: resource, persistenceLoadProducer: nil, remoteProducer: nil, fetchType: .config)
    }

    func fetchStuff(resource: Resource, explicitFetchType: DataProviderFetchType) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        return fetchStuff(resource: resource, persistenceLoadProducer: nil, remoteProducer: nil, fetchType: explicitFetchType)
    }

    func fetchStuff(
        resource: Resource,
        persistenceLoadProducer: AnyPublisher<(T, DataProviderSource), DataProviderError>?,
        remoteProducer: AnyPublisher<(T, DataProviderSource), DataProviderError>?,
        fetchType: DataProviderFetchType
    ) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        switch fetchType {
        case .config:
            return fetchForTypeConfig(
                input: resource,
                persistenceLoadProducer: { persistenceLoadProducer ?? dataProviderPersistenceLoadProducer(resource: resource) },
                remoteProducer: { remoteProducer ?? dataProviderRemoteProducer(resource: resource) }
            )
        case .local:
            return persistenceLoadProducer ?? dataProviderPersistenceLoadProducer(resource: resource)
        case .remote:
            return remoteProducer ?? dataProviderRemoteProducer(resource: resource)
        }
    }
}

extension DataProvider: Fetchable {
    typealias E = DataProviderError
    typealias I = (Resource, DataProviderFetchType)
    typealias V = (T, DataProviderSource)

    func fetchData(_ input: I) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        switch input.1 {
        case .config:
            return fetchForTypeConfig(
                input: input.0,
                persistenceLoadProducer: { dataProviderPersistenceLoadProducer(resource: input.0) },
                remoteProducer: { dataProviderRemoteProducer(resource: input.0) }
            )
        case .local:
            return dataProviderPersistenceLoadProducer(resource: input.0)
        case .remote:
            return dataProviderRemoteProducer(resource: input.0)
        }
    }

    private func fetchForTypeConfig(
        input: Resource,
        persistenceLoadProducer: @escaping () -> AnyPublisher<(T, DataProviderSource), DataProviderError>,
        remoteProducer: @escaping () -> AnyPublisher<(T, DataProviderSource), DataProviderError>
    ) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        // Guard for just local data provider config
        guard config.remoteEnabled else {
            return persistenceLoadProducer()
        }

        // Guard for just remote data provider config
        guard config.persistenceEnabled else {
            return remoteProducer()
        }

        // Hybrid
        guard config.remoteFirst else {
            guard config.sendMultipleValuesFromBothLayers else {
                // Fetch from the persistence layer and on error use remote
                return persistenceLoadProducer()
                    .catch({ _ in remoteProducer()})
                    .eraseToAnyPublisher()
            }

            // Fetch from the persistence layer and send the values.
            // Then fetch remotely and send those values as well or empty if the remote fetch fails.
            return persistenceLoadProducer()
                .merge(with: remoteProducer().catch { _ in Empty<(T, DataProviderSource), DataProviderError>() }.eraseToAnyPublisher())
                .catch({ _ in remoteProducer() })
                .eraseToAnyPublisher()
        }

        guard config.sendMultipleValuesFromBothLayers else {
            // Fetch remotly and on error use the persistence layer
            return remoteProducer()
                .catch({ _ in persistenceLoadProducer() })
                .eraseToAnyPublisher()
        }

        // Firstly fetch from the remote and send the values.
        // Then fetch from persistence layer and send those values as well or empty if the persistence layer fails.
        return remoteProducer()
            .merge(with: persistenceLoadProducer().catch { _ in Empty<(T, DataProviderSource), DataProviderError>() }.eraseToAnyPublisher())
            .catch({ _ in persistenceLoadProducer() })
            .eraseToAnyPublisher()
    }

    private func dataProviderPersistenceLoadProducer(resource: Resource) -> AnyPublisher<V, DataProviderError> {
        return handlers
            .persistenceLoadHandler(persistence, resource)
            .receive(on: DispatchQueue(label: "DataProvider.persistenceProducer"))
            .mapError({ DataProviderError.persistence(error: $0) })
            .map({ ($0, DataProviderSource.local) })
            .eraseToAnyPublisher()
    }

    private func dataProviderRemoteProducer(resource: Resource) -> AnyPublisher<V, DataProviderError> {
        return handlers
            .networkHandler(network, network.buildUrlRequest(resource: resource))
            .receive(on: DispatchQueue(label: "DataProvider.networkHandler"))
            .flatMap(handlers.networkParserHandler)
            .map({ ($0, DataProviderSource.remote) })
            .subscribe(on: DispatchQueue(label: "DataProvider.parserHandler"))
            .eraseToAnyPublisher()
    }
}

extension DataProvider: DataProviderNetworkProtocol {
    func buildUrlRequest(resource: Resource) -> URLRequest {
        network.buildUrlRequest(resource: resource)
    }
    
    func fetchData(request: URLRequest) -> AnyPublisher<(Data, URLResponse), DataProviderError> {
        network.fetchData(request: request)
    }
}

extension DataProvider: DataProviderPersistenceProtocol {
    func fetchResource<T>(_ resource: Resource) -> AnyPublisher<T, PersistenceLayerError> {
        persistence.fetchResource(resource)
    }

    func persistObjects<T>(_ objects: T, saveCompletion: @escaping PersistenceSaveCompletion) {
        persistence.persistObjects(objects, saveCompletion: saveCompletion)
    }

    func removeResource(_ resource: Resource) -> AnyPublisher<Bool, PersistenceLayerError> {
        persistence.removeResource(resource)
    }
}
