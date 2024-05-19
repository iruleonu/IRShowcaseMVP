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

// sourcery: AutoMockable
protocol PersistenceLayerLoad {
    func fetchResource<T>(_ resource: Resource) -> AnyPublisher<T, PersistenceLayerError>
}

// sourcery: AutoMockable
protocol PersistenceLayerSave {
    func persistObjects<T>(_ objects: T, saveCompletion: @escaping PersistenceSaveCompletion)
}

// sourcery: AutoMockable
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
        case .dummyProducts:
            fallthrough
        case .dummyProductsAll:
            return Future { promise in
                let fileName = String(describing: type(of: DummyProductDataContainer.self)) + resource.rawValue
                let savedFile: DummyProductDataContainer? = FileManager.object(from: fileName)
                guard let casted = savedFile as? T else {
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
        switch objects {
        case let t as DummyProductDataContainer:
            persistDummyProductsDataContainer(t, saveCompletion: saveCompletion)
        default:
            saveCompletion(false, PersistenceLayerError.notImplemented)
        }
    }

    private func persistDummyProductsDataContainer(_ object: DummyProductDataContainer, saveCompletion: @escaping PersistenceSaveCompletion) {
        let resource: Resource = .dummyProducts(limit: object.limit, skip: object.skip)
        let fileName = String(describing: type(of: DummyProductDataContainer.self)) + resource.rawValue
        let (jsonString, error) = JSONEncoder.encodeObjectToString(from: object, filename: fileName)

        if let jsonString = jsonString {
            FileManager.saveStringToDocumentDirectory(jsonString, filename: fileName)
        }

        saveCompletion(error == nil, error)
    }
}

extension PersistenceLayerImpl: PersistenceLayerRemove {
    func removeResource(_ resource: Resource) -> AnyPublisher<Bool, PersistenceLayerError> {
        return Future { promise in
            promise(.failure(PersistenceLayerError.notImplemented))
        }.eraseToAnyPublisher()
    }
}
