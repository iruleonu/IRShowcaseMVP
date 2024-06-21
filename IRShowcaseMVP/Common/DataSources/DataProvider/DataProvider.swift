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

enum DataProviderSource: String, Sendable {
    case local
    case remote
}

enum DataProviderFetchType {
    case config // defaults to the used data provider configuration
    case local
    case remote
}

// sourcery: AutoMockable
// sourcery: associatedtype = "TP: Codable & Sendable"
protocol DataProviderCombineProtocol {
    associatedtype TP: Codable & Sendable

    func fetchStuffPublisher(resource: Resource) -> AnyPublisher<(TP, DataProviderSource), DataProviderError>
    func fetchStuffPublisher(resource: Resource, explicitFetchType: DataProviderFetchType) -> AnyPublisher<(TP, DataProviderSource), DataProviderError>
    func fetchStuffPublisher(
        resource: Resource,
        persistenceLoadProducer: AnyPublisher<(TP, DataProviderSource), DataProviderError>?,
        remoteProducer: AnyPublisher<(TP, DataProviderSource), DataProviderError>?,
        fetchType: DataProviderFetchType
    ) -> AnyPublisher<(TP, DataProviderSource), DataProviderError>
}

// sourcery: AutoMockable
// sourcery: associatedtype = "TP: Codable & Sendable"
protocol DataProviderAsyncProtocol {
    associatedtype TP: Codable & Sendable

    func fetchStuff(resource: Resource) async throws -> [(TP, DataProviderSource)]
    func fetchStuff(resource: Resource, explicitFetchType: DataProviderFetchType) async throws -> [(TP, DataProviderSource)]
    func fetchStuff(
        resource: Resource,
        persistenceLoadProducer: (@Sendable () async throws -> (TP, DataProviderSource))?,
        remoteProducer: (@Sendable () async throws -> (TP, DataProviderSource))?,
        fetchType: DataProviderFetchType
    ) async throws -> [(TP, DataProviderSource)]
}

// sourcery: AutoMockable
// sourcery: associatedtype = "TP: Codable & Sendable"
protocol DataProviderProtocol: DataProviderAsyncProtocol, DataProviderCombineProtocol where TP: Codable & Sendable {
    var config: DataProviderConfiguration { get }
    var network: DataProviderNetworkProtocol { get }
    var persistence: DataProviderPersistenceProtocol { get }
    var handlers: DataProviderHandlers<TP> { get }
}

struct DataProvider<Type: Codable & Sendable>: DataProviderProtocol, Sendable {
    typealias T = Type
    typealias TP = Type
    let config: DataProviderConfiguration
    let network: DataProviderNetworkProtocol
    let persistence: DataProviderPersistenceProtocol
    let handlers: DataProviderHandlers<T>
    let publisherHandlers: DataProviderPublisherHandlers<T>

    init(
        config c: DataProviderConfiguration,
        network n: DataProviderNetworkProtocol,
        persistence p: DataProviderPersistenceProtocol,
        handlers h: DataProviderHandlers<T>,
        publisherHandlers ph: DataProviderPublisherHandlers<T>
    ) {
        config = c
        network = n
        persistence = p
        handlers = h
        publisherHandlers = ph
    }

    // DataProviderCombineProtocol
    func fetchStuffPublisher(resource: Resource) -> AnyPublisher<(TP, DataProviderSource), DataProviderError> {
        return fetchStuffPublisher(resource: resource, persistenceLoadProducer: nil, remoteProducer: nil, fetchType: .config)
    }

    func fetchStuffPublisher(resource: Resource, explicitFetchType: DataProviderFetchType) -> AnyPublisher<(TP, DataProviderSource), DataProviderError> {
        return fetchStuffPublisher(resource: resource, persistenceLoadProducer: nil, remoteProducer: nil, fetchType: explicitFetchType)
    }

    func fetchStuffPublisher(
        resource: Resource,
        persistenceLoadProducer: AnyPublisher<(TP, DataProviderSource), DataProviderError>?,
        remoteProducer: AnyPublisher<(TP, DataProviderSource), DataProviderError>?,
        fetchType: DataProviderFetchType
    ) -> AnyPublisher<(TP, DataProviderSource), DataProviderError> {
        switch fetchType {
        case .config:
            return fetchForTypeConfigPublisher(
                input: resource,
                persistenceLoadProducer: { persistenceLoadProducer ?? dataProviderPersistenceLoadPublisher(resource: resource) },
                remoteProducer: { remoteProducer ?? dataProviderRemotePublisher(resource: resource) }
            )
        case .local:
            return persistenceLoadProducer ?? dataProviderPersistenceLoadPublisher(resource: resource)
        case .remote:
            return remoteProducer ?? dataProviderRemotePublisher(resource: resource)
        }
    }

    // DataProviderAsyncProtocol
    func fetchStuff(resource: Resource) async throws -> [(T, DataProviderSource)] {
        return try await fetchStuff(resource: resource, persistenceLoadProducer: nil, remoteProducer: nil, fetchType: .config)
    }

    func fetchStuff(resource: Resource, explicitFetchType: DataProviderFetchType) async throws -> [(T, DataProviderSource)] {
        return try await fetchStuff(resource: resource, persistenceLoadProducer: nil, remoteProducer: nil, fetchType: explicitFetchType)
    }

    func fetchStuff(
        resource: Resource,
        persistenceLoadProducer: (@Sendable () async throws -> (T, DataProviderSource))?,
        remoteProducer: (@Sendable () async throws -> (T, DataProviderSource))?,
        fetchType: DataProviderFetchType
    ) async throws -> [(T, DataProviderSource)] {
        switch fetchType {
        case .config:
            return try await fetchForTypeConfigAsync(
                input: resource,
                persistenceLoadProducer: {
                    if let persistenceLoadProducer = persistenceLoadProducer {
                        return try await persistenceLoadProducer()
                    } else {
                        return try await dataProviderPersistenceLoadAsync(resource: resource)
                    }
                },
                remoteProducer: {
                    if let remoteProducer = remoteProducer {
                        return try await remoteProducer()
                    } else {
                        return try await dataProviderRemoteAsync(resource: resource)
                    }
                }
            )
        case .local:
            return [try await dataProviderPersistenceLoadAsync(resource: resource)]
        case .remote:
            return [try await dataProviderRemoteAsync(resource: resource)]
        }
    }
}

extension DataProvider: Fetchable {
    typealias E = DataProviderError
    typealias I = (Resource, DataProviderFetchType)
    typealias V = (T, DataProviderSource)

    func fetchDataSingle(_ input: I) async throws -> V {
        switch input.1 {
        case .config:
            guard let firstValue = try await fetchForTypeConfigAsync(
                input: input.0,
                persistenceLoadProducer: { try await dataProviderPersistenceLoadAsync(resource: input.0) },
                remoteProducer: { try await dataProviderRemoteAsync(resource: input.0) }
            ).first else {
                throw DataProviderError.noDataFromFetch
            }
            return firstValue
        case .local:
            return try await dataProviderPersistenceLoadAsync(resource: input.0)
        case .remote:
            return try await dataProviderRemoteAsync(resource: input.0)
        }
    }

    func fetchData(_ input: I) async throws -> [(T, DataProviderSource)] {
        switch input.1 {
        case .config:
            return try await fetchForTypeConfigAsync(
                input: input.0,
                persistenceLoadProducer: { try await dataProviderPersistenceLoadAsync(resource: input.0) },
                remoteProducer: { try await dataProviderRemoteAsync(resource: input.0) }
            )
        case .local:
            return [try await dataProviderPersistenceLoadAsync(resource: input.0)]
        case .remote:
            return [try await dataProviderRemoteAsync(resource: input.0)]
        }
    }

    func fetchDataPublisher(_ input: (Resource, DataProviderFetchType)) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        switch input.1 {
        case .config:
            return fetchForTypeConfigPublisher(
                input: input.0,
                persistenceLoadProducer: { dataProviderPersistenceLoadPublisher(resource: input.0) },
                remoteProducer: { dataProviderRemotePublisher(resource: input.0) }
            )
        case .local:
            return dataProviderPersistenceLoadPublisher(resource: input.0)
        case .remote:
            return dataProviderRemotePublisher(resource: input.0)
        }
    }
}

// Combine/publisher related
private extension DataProvider {
    func fetchForTypeConfigPublisher(
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

    func dataProviderPersistenceLoadPublisher(resource: Resource) -> AnyPublisher<V, DataProviderError> {
        return publisherHandlers
            .persistenceLoadHandler(persistence, resource)
            .receive(on: DispatchQueue(label: "DataProvider.persistenceProducer"))
            .mapError({ DataProviderError.persistence(error: $0) })
            .map({ ($0, DataProviderSource.local) })
            .eraseToAnyPublisher()
    }

    func dataProviderRemotePublisher(resource: Resource) -> AnyPublisher<V, DataProviderError> {
        return publisherHandlers
            .networkHandler(network, network.buildUrlRequest(resource: resource))
            .receive(on: DispatchQueue(label: "DataProvider.networkHandler"))
            .flatMap(publisherHandlers.networkParserHandler)
            .map({ ($0, DataProviderSource.remote) })
            .subscribe(on: DispatchQueue(label: "DataProvider.parserHandler"))
            .eraseToAnyPublisher()
    }
}

// Async related
private extension DataProvider {
    func fetchForTypeConfigAsync(
        input: Resource,
        persistenceLoadProducer: @escaping @Sendable () async throws -> (T, DataProviderSource),
        remoteProducer: @escaping @Sendable () async throws -> (T, DataProviderSource)
    ) async throws -> [(T, DataProviderSource)] {
        // Guard for just local data provider config
        guard config.remoteEnabled else {
            return [try await persistenceLoadProducer()]
        }

        // Guard for just remote data provider config
        guard config.persistenceEnabled else {
            return [try await remoteProducer()]
        }

        // Hybrid
        guard config.remoteFirst else {
            guard config.sendMultipleValuesFromBothLayers else {
                // Fetch from the persistence layer and on error use remote
                do {
                    return [try await persistenceLoadProducer()]
                } catch {
                    return [try await remoteProducer()]
                }
            }

            // Fetch from the persistence layer and send the values.
            // Then fetch remotely and send those values as well or empty if the remote fetch fails.
            do {
                var results: [(T, DataProviderSource)] = []
                let persistenceLoadValue = try await persistenceLoadProducer()
                results.append(persistenceLoadValue)

                let remoteProducerValue: (T, DataProviderSource)?
                do {
                    remoteProducerValue = try await remoteProducer()
                } catch {
                    remoteProducerValue = nil
                }
                if let remoteProducerValue = remoteProducerValue {
                    results.append(remoteProducerValue)
                }

                return results
            } catch {
                return [try await remoteProducer()]
            }
        }

        guard config.sendMultipleValuesFromBothLayers else {
            // Fetch remotly and on error use the persistence layer
            do {
                return [try await remoteProducer()]
            } catch {
                return [try await persistenceLoadProducer()]
            }
        }

        // Firstly fetch from the remote and send the values.
        // Then fetch from persistence layer and send those values as well or empty if the persistence layer fails.
        do {
            var results: [(T, DataProviderSource)] = []
            let remoteProducerValue = try await remoteProducer()
            results.append(remoteProducerValue)

            let persistenceLoadValue: (T, DataProviderSource)?
            do {
                persistenceLoadValue = try await persistenceLoadProducer()
            } catch {
                persistenceLoadValue = nil
            }
            if let persistenceLoadValue = persistenceLoadValue {
                results.append(persistenceLoadValue)
            }

            return results
        } catch {
            return [try await persistenceLoadProducer()]
        }
    }

    func dataProviderPersistenceLoadAsync(resource: Resource) async throws -> V {
        let persistenceData = try await handlers.persistenceLoadHandler(persistence, resource)
        return (persistenceData, .local)
    }

    func dataProviderRemoteAsync(resource: Resource) async throws -> V {
        let networkData = try await handlers.networkHandler(network, network.buildUrlRequest(resource: resource))
        let parsedNetworkData = try await handlers.networkParserHandler(networkData)
        return (parsedNetworkData, .remote)
    }
}
