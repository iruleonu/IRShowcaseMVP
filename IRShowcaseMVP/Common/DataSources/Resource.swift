//
//  APIServiceRoute.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 20/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation

enum Resource {
    case unknown
    case babyNamePopularities
    case dummyProducts
}

extension Resource {
    var requestProperties: (method: RequestMethod, path: String, query: [String: Any]) {
        switch self {
        case .unknown:
            return (.GET, "", [:])
        case .babyNamePopularities:
            return (.GET, "/views/25th-nujf/rows.json", [:])
        case .dummyProducts:
            return (.GET, "/products", ["limit":"100"])
        }
    }
}

extension Resource {
    func buildUrlRequest(apiBaseUrl: URL) -> URLRequest {
        return buildUrlRequest(apiBaseUrl: apiBaseUrl, authBearer: nil, contentType: nil)
    }

    func buildUrlRequest(apiBaseUrl: URL, authBearer: String?, contentType: String?) -> URLRequest {
        var components = URLComponents(url: apiBaseUrl, resolvingAgainstBaseURL: false)
        components?.queryItems = Resource.buildQueryItems(requestProperties.query)
        components?.path = requestProperties.path
        let finalURL = components?.url ?? apiBaseUrl
        let request = NSMutableURLRequest(url: finalURL)
        request.httpMethod = requestProperties.method.rawValue

        if let authBearer = authBearer {
            request.setValue(
                "Bearer \(authBearer)",
                forHTTPHeaderField: "Authentication"
            )
        }

        if let contentType = contentType {
            request.setValue(
                contentType,
                forHTTPHeaderField: "Content-Type"
            )
        }

        return request as URLRequest
    }

    fileprivate static func buildQueryItems(_ query: [String: Any]) -> [URLQueryItem]? {
        guard !query.isEmpty else { return nil }
        return query.compactMap({ tuple in
            guard let value = tuple.value as? String else { return nil }
            return URLQueryItem(name: tuple.key, value: value)
        })
    }
}

extension Resource: Equatable {
    static func == (lhs: Resource, rhs: Resource) -> Bool {
        let samePath: Bool
        let sameParams: Bool
        
        switch (lhs.requestProperties, rhs.requestProperties) {
        case (let (_, lPath, lParams), let (_, rPath, rParams)):
            samePath = lPath == rPath
            let lQueryItems = Resource.buildQueryItems(lParams)
            let rQueryItems = Resource.buildQueryItems(rParams)
            sameParams = lQueryItems == rQueryItems
        }
        
        return samePath && sameParams
    }
}
