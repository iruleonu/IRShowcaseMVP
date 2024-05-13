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
    static let standard: DataProviderConfiguration = remoteIfErrorUseLocal

    static let localOnly: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: false, remoteFirst: false)
    }()

    static let remoteOnly: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: false, remoteEnabled: true, remoteFirst: true)
    }()

    static let localIfErrorUseRemote: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: false)
    }()

    static let remoteIfErrorUseLocal: DataProviderConfiguration = {
        return DataProviderConfiguration(persistenceEnabled: true, remoteEnabled: true, remoteFirst: true)
    }()

    let persistenceEnabled: Bool
    let remoteEnabled: Bool
    let remoteFirst: Bool

    init(persistenceEnabled pe: Bool, remoteEnabled re: Bool, remoteFirst rf: Bool) {
        persistenceEnabled = pe
        remoteEnabled = re
        remoteFirst = rf
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
        // Guard for persistenceFirst - Load persisted values first, fallback to remote when the local fetch fails
        guard config.remoteFirst else {
            return persistenceLoadProducer(resource: input)
                .flatMap({ persistenceValue in
                    remoteProducer(resource: input)
                        .catch { _ in Just<(T, DataProviderSource)>(persistenceValue) }
                        .eraseToAnyPublisher()
                })
                .catch({ _ in remoteProducer(resource: input) }).eraseToAnyPublisher()
        }

        // Load remotely first, fallback to the persisted values when the remote fetch fails
        return remoteProducer(resource: input)
            .flatMap({ remoteValue in
                persistenceLoadProducer(resource: input)
                    .catch { _ in Just<(T, DataProviderSource)>(remoteValue) }
                    .eraseToAnyPublisher()
            })
            .catch({ _ in persistenceLoadProducer(resource: input).eraseToAnyPublisher() }).eraseToAnyPublisher()
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
