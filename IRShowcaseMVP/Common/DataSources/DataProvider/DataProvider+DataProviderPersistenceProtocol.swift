//
//  DataProvider+DataProviderPersistenceProtocol.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 22/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

extension DataProvider: DataProviderPersistenceProtocol {
    func fetchResourcePublisher<T>(_ resource: Resource) -> AnyPublisher<T, PersistenceLayerError> {
        persistence.fetchResourcePublisher(resource)
    }

    func removeResourcePublisher(_ resource: Resource) -> AnyPublisher<Bool, PersistenceLayerError> {
        persistence.removeResourcePublisher(resource)
    }

    func fetchResource<T>(_ resource: Resource) async throws -> T {
        try await persistence.fetchResource(resource)
    }

    func persistObjects<T>(_ objects: T, saveCompletion: @escaping PersistenceSaveCompletion) {
        persistence.persistObjects(objects, saveCompletion: saveCompletion)
    }

    func removeResource(_ resource: Resource) async throws -> Bool {
        try await persistence.removeResource(resource)
    }
}
