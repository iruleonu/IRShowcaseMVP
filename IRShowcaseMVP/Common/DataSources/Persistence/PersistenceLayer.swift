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
                let fileName = PersistenceLayerImpl.fileNameForResource(resource)
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
        let fileName = PersistenceLayerImpl.fileNameForResource(resource)
        let (jsonString, error) = JSONEncoder.encodeObjectToString(from: object, filename: fileName)

        if let jsonString = jsonString {
            FileManager.saveStringToDocumentDirectory(jsonString, filename: fileName)
        }

        // If the data continer has all the objects, save as a resource so that we have data
        // when fetching for the Resource .dummyProductsAll
        let paginatedTotal = object.limit + object.skip
        let apiReportedTotal = object.total
        let productsTotal = object.products.count
        let dataContainerHasAllTheObjects = paginatedTotal >= apiReportedTotal && productsTotal >= apiReportedTotal
        if (dataContainerHasAllTheObjects) {
            let fileNameResourceDummyProductsAll = PersistenceLayerImpl.fileNameForResource(.dummyProductsAll)
            let (jsonForDummyProductsAllString, _) = JSONEncoder.encodeObjectToString(from: object, filename: fileNameResourceDummyProductsAll)
            if let jsonForDummyProductsAllString = jsonForDummyProductsAllString {
                FileManager.saveStringToDocumentDirectory(jsonForDummyProductsAllString, filename: fileNameResourceDummyProductsAll)
            }
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

private extension PersistenceLayerImpl {
    static func fileNameForResource(_ resource: Resource) -> String {
        switch resource {
        case .babyNamePopularities:
            return String(describing: type(of: BabyNamePopularityDataContainer.self)) + resource.rawValue
        case .dummyProducts:
            fallthrough
        case .dummyProductsAll:
            return String(describing: type(of: DummyProductDataContainer.self)) + resource.rawValue
        case .unknown:
            return ""
        }
    }
}
