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

enum DataProviderSource {
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
}

struct DataProviderConfiguration {
    static let standard: DataProviderConfiguration = remoteOnErrorUseLocal

    static let localOnly: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: false, remoteFirst: false, sendMultipleValuesFromBothLayers: false)
    }()

    static let remoteOnly: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: false, remoteEnabled: true, remoteFirst: true, sendMultipleValuesFromBothLayers: false)
    }()

    static let localOnErrorUseRemote: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: false, sendMultipleValuesFromBothLayers: false)
    }()

    static let remoteOnErrorUseLocal: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: true, sendMultipleValuesFromBothLayers: false)
    }()
    
    static let localFirstThenRemote: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: false, sendMultipleValuesFromBothLayers: true)
    }()

    static let remoteFirstThenLocal: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: true, sendMultipleValuesFromBothLayers: true)
    }()

    let persistenceEnabled: Bool
    let remoteEnabled: Bool
    let remoteFirst: Bool
    let sendMultipleValuesFromBothLayers: Bool

    init(persistenceEnabled pe: Bool, remoteEnabled re: Bool, remoteFirst rf: Bool, sendMultipleValuesFromBothLayers smvfbl: Bool) {
        persistenceEnabled = pe
        remoteEnabled = re
        remoteFirst = rf
        sendMultipleValuesFromBothLayers = smvfbl
    }
}

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
        return fetchData((resource, .config))
    }

    func fetchStuff(resource: Resource, explicitFetchType: DataProviderFetchType) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        return fetchData((resource, explicitFetchType))
    }
}

extension DataProvider {
    func saveToPersistence(_ elements: T) -> AnyPublisher<T, DataProviderError> {
        return handlers.persistenceSaveHandler(persistence, elements)
    }

    func removeEntities(forResource resource: Resource) -> AnyPublisher<Bool, DataProviderError> {
        return handlers.persistenceRemoveHandler(persistence, resource)
    }
}

extension DataProvider: Fetchable {
    typealias E = DataProviderError
    typealias I = (Resource, DataProviderFetchType)
    typealias V = (T, DataProviderSource)

    func fetchData(_ input: I) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        switch input.1 {
        case .config:
            return fetchForTypeConfig(input: input.0)
        case .local:
            return fetchForTypeLocal(input: input.0)
        case .remote:
            return fetchForTypeRemote(input: input.0)
        }
    }

    private func fetchForTypeConfig(input: Resource) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        // Guard for just local data provider config
        guard config.remoteEnabled else {
            return persistenceLoadProducer(resource: input)
        }

        // Guard for just remote data provider config
        guard config.persistenceEnabled else {
            return remoteProducer(resource: input)
        }

        // Hybrid
        guard config.remoteFirst else {
            guard config.sendMultipleValuesFromBothLayers else {
                // Fetch from the persistence layer and on error use remote
                return persistenceLoadProducer(resource: input)
                    .catch({ _ in remoteProducer(resource: input) }).eraseToAnyPublisher()
                    .eraseToAnyPublisher()
            }

            // Fetch from the persistence layer and send the values.
            // Then fetch remotely and send those values as well or empty if the remote fetch fails.
            return persistenceLoadProducer(resource: input)
                .merge(with: remoteProducer(resource: input).catch { _ in Empty<(T, DataProviderSource), DataProviderError>() }.eraseToAnyPublisher())
                .catch({ _ in remoteProducer(resource: input) }).eraseToAnyPublisher()
                .eraseToAnyPublisher()
        }

        guard config.sendMultipleValuesFromBothLayers else {
            // Fetch remotly and on error use the persistence layer
            return remoteProducer(resource: input)
                .catch({ _ in persistenceLoadProducer(resource: input) }).eraseToAnyPublisher()
                .eraseToAnyPublisher()
        }

        // Firstly fetch from the remote and send the values.
        // Then fetch from persistence layer and send those values as well or empty if the persistence layer fails.
        return remoteProducer(resource: input)
            .merge(with: persistenceLoadProducer(resource: input).catch { _ in Empty<(T, DataProviderSource), DataProviderError>() }.eraseToAnyPublisher())
            .catch({ _ in persistenceLoadProducer(resource: input) }).eraseToAnyPublisher()
            .eraseToAnyPublisher()
    }

    private func fetchForTypeLocal(input: Resource) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        return persistenceLoadProducer(resource: input)
    }

    private func fetchForTypeRemote(input: Resource) -> AnyPublisher<(T, DataProviderSource), DataProviderError> {
        return remoteProducer(resource: input)
    }

    private func persistenceLoadProducer(resource: Resource) -> AnyPublisher<V, DataProviderError> {
        return handlers
            .persistenceLoadHandler(persistence, resource)
            .receive(on: DispatchQueue(label: "DataProvider.persistenceProducer"))
            .mapError({ DataProviderError.persistence(error: $0) })
            .map({ ($0, DataProviderSource.local) })
            .eraseToAnyPublisher()
    }

    private func remoteProducer(resource: Resource) -> AnyPublisher<V, DataProviderError> {
        return handlers
            .networkHandler(network, network.buildUrlRequest(resource: resource))
            .receive(on: DispatchQueue(label: "DataProvider.networkHandler"))
            .flatMap(handlers.networkParserHandler)
            .map({ ($0, DataProviderSource.remote) })
            .subscribe(on: DispatchQueue(label: "DataProvider.parserHandler"))
            .eraseToAnyPublisher()
    }
}
