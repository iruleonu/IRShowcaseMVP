//
//  PersistenceLayer.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 10/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

typealias PersistenceSaveCompletion = (Bool, Error?) -> Void

protocol PersistenceLayerLoad {
    func fetchResource<T>(_ resource: Resource) -> AnyPublisher<T, PersistenceLayerError>
}

protocol PersistenceLayerSave {
    func persistObjects<T>(_ objects: T, saveCompletion: @escaping PersistenceSaveCompletion)
}

protocol PersistenceLayerRemove {
    func removeResource(_ resource: Resource) -> AnyPublisher<Bool, PersistenceLayerError>
}

//sourcery: AutoMockable
protocol PersistenceLayer: PersistenceLayerLoad, PersistenceLayerSave, PersistenceLayerRemove {

}

class PersistenceLayerImpl {
    init() {}
}

extension PersistenceLayerImpl: PersistenceLayerLoad {
    func fetchResource<T>(_ resource: Resource) -> AnyPublisher<T, PersistenceLayerError> {
        switch resource {
        case .babyNamePopularities:
            return Future { promise in
                let babyNamePopularities: BabyNamePopularityDataContainer = ReadFile.object(from: "babyNamePopularities", extension: "json")
                guard let casted = babyNamePopularities as? T else {
                    promise(.failure(PersistenceLayerError.casting))
                    return
                }
                promise(.success(casted))
            }.eraseToAnyPublisher()
        default:
            return Future { promise in
                promise(.failure(PersistenceLayerError.notImplemented))
            }.eraseToAnyPublisher()
        }
    }
}

extension PersistenceLayerImpl: PersistenceLayerSave {
    func persistObjects<T>(_ objects: T, saveCompletion: @escaping PersistenceSaveCompletion) {
        saveStaticElemsToJSON()
        saveCompletion(false, PersistenceLayerError.notImplemented)
    }
}

extension PersistenceLayerImpl: PersistenceLayerRemove {
    func removeResource(_ resource: Resource) -> AnyPublisher<Bool, PersistenceLayerError> {
        return Future { promise in
            promise(.failure(PersistenceLayerError.notImplemented))
        }.eraseToAnyPublisher()
    }
}

