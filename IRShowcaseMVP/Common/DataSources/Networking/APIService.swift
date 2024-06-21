//
//  APIService.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 20/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation

enum APIServiceError: Error {
    case unknown
    case parsing(error: Error)
    case network(error: Error)
    
    var errorDescription: String {
        switch self {
        case .parsing(let error):
            return "Parsing: \(error.localizedDescription)"
        case .network(let error):
            return "Network: \(error.localizedDescription)"
        default:
            return "Unknown error"
        }
    }
}

enum RequestMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

//sourcery: AutoMockable
protocol APIService: APIURLRequestProtocol, URLRequestFetchable {
    var serverConfig: ServerConfigProtocol { get }
    init(serverConfig: ServerConfigProtocol)
}

protocol APIBaseUrlProtocol: Sendable {
    var apiBaseUrl: URL { get }
}

protocol APIAuthBearerKeyProtocol: Sendable {
    var apiAuthBearerKey: String { get }
}

protocol APIUserAgentProtocol: Sendable {
    var apiUserAgent: String { get }
}

protocol APIURLRequestProtocol: Sendable {
    func buildUrlRequest(resource: Resource) -> URLRequest
}

protocol ServerConfigProtocol: APIBaseUrlProtocol, APIAuthBearerKeyProtocol, APIUserAgentProtocol {}

struct ServerConfig: ServerConfigProtocol {
    let apiBaseUrl: URL
    let apiAuthBearerKey: String
    let apiUserAgent: String

    init(
        apiBaseUrl: String = NSObject.APIBaseUrl ?? "",
        apiAuthBearerKey: String = NSObject.APIAuthBearerKey ?? "",
        apiUserAgent: String = NSObject.APIUserAgent ?? ""
    ) {
        self.apiBaseUrl = URL(string: apiBaseUrl)!
        self.apiAuthBearerKey = apiAuthBearerKey
        self.apiUserAgent = apiUserAgent
    }
}

extension APIService {
    var apiBaseUrl: URL {
        return serverConfig.apiBaseUrl
    }
}

struct APIServiceImpl: APIService {
    let session: URLSession
    let serverConfig: ServerConfigProtocol
    
    init(serverConfig sc: ServerConfigProtocol = ServerConfig()) {
        serverConfig = sc

        let sessionConfiguration = URLSessionConfiguration.default
        
        var httpAdditionalHeaders: [String : String] = [:]
        if serverConfig.apiAuthBearerKey.count > 0 {
            httpAdditionalHeaders["Authorization"] = "Bearer \(serverConfig.apiAuthBearerKey)"
        }
        if serverConfig.apiUserAgent.count > 0 {
            httpAdditionalHeaders["User-Agent"] = serverConfig.apiUserAgent
        }
        if (httpAdditionalHeaders.count > 0) {
            sessionConfiguration.httpAdditionalHeaders = httpAdditionalHeaders
        }

        session = URLSession(configuration: sessionConfiguration)
    }
}

extension APIServiceImpl: APIBaseUrlProtocol {
    var apiBaseUrl: URL {
        return serverConfig.apiBaseUrl
    }
}

extension APIServiceImpl: APIAuthBearerKeyProtocol {
    var apiAuthBearerKey: String {
        return serverConfig.apiAuthBearerKey
    }
}

extension APIServiceImpl: APIURLRequestProtocol {
    func buildUrlRequest(resource: Resource) -> URLRequest {
        return resource.buildUrlRequest(apiBaseUrl: apiBaseUrl)
    }
}
