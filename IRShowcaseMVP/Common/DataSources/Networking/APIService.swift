//
//  APIService.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 20/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation
import UIKit
import Combine

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

protocol APIBaseUrlProtocol {
    var apiBaseUrl: URL { get }
}

protocol APIURLRequestProtocol {
    func buildUrlRequest(resource: Resource) -> URLRequest
}

protocol ServerConfigProtocol: APIBaseUrlProtocol {
    
}

struct ServerConfig: ServerConfigProtocol {
    var apiBaseUrl: URL
    
    init(apiBaseUrl: String = NSObject.APIBaseUrl ?? "") {
        self.apiBaseUrl = URL(string: apiBaseUrl)!
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
        session = URLSession.shared
    }
}

extension APIServiceImpl: AppService {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}

extension APIServiceImpl: Fetchable {
    typealias I = URLRequest
    typealias V = (Data, URLResponse)
    typealias E = DataProviderError
    
    func fetchData(_ input: I) -> AnyPublisher<V, E> {
        return session.fetchData(input)
    }
}

extension APIServiceImpl: URLRequestFetchable {
    func fetchData(request: URLRequest) -> AnyPublisher<(Data, URLResponse), DataProviderError> {
        return session.fetchData(request)
    }
}

extension APIServiceImpl: APIBaseUrlProtocol {
    var apiBaseUrl: URL {
        return serverConfig.apiBaseUrl
    }
}

extension APIServiceImpl: APIURLRequestProtocol {
    func buildUrlRequest(resource: Resource) -> URLRequest {
        return resource.buildUrlRequest(apiBaseUrl: apiBaseUrl)
    }
}
