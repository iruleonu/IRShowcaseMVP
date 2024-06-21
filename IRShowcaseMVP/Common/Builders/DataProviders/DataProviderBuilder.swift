//
//  DataProviderBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct DataProviderBuilder {
    static func makeDataProvider<T: Codable>(config: DataProviderConfiguration, network: DataProviderNetworkProtocol, persistence: DataProviderPersistenceProtocol) -> DataProvider<T> {
        let handlersFactory: DataProviderHandlersBuilder<T> = DataProviderHandlersBuilder()
        let handlers: DataProviderHandlers<T> = handlersFactory.makeDataProviderHandlers(config: config)

        let publisherHandlersFactory: DataProviderPublisherHandlersBuilder<T> = DataProviderPublisherHandlersBuilder()
        let publisherHandlers: DataProviderPublisherHandlers<T> = publisherHandlersFactory.makeDataProviderPublisherHandlers(config: config)

        return DataProvider<T>(config: config, network: network, persistence: persistence, handlers: handlers, publisherHandlers: publisherHandlers)
    }
}
