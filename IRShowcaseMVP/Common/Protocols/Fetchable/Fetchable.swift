//
//  Fetchable.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 21/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation
import Combine

protocol Fetchable {
    associatedtype I
    associatedtype V
    associatedtype E: Error
    func fetchDataPublisher(_ input: I) -> AnyPublisher<V, E>
    func fetchDataSingle(_ input: I) async throws -> V
    func fetchData(_ input: I) async throws -> [V]
}
