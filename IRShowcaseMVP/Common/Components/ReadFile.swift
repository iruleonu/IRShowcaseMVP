//
//  ReadFile.swift
//  IRCV
//
//  Created by Nuno Salvador on 17/06/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation

class ReadFile {
    static func object<T: Codable>(from filename: String, extension type: String) -> T {
        return object(from: filename, extension: type, bundle: Bundle(for: self))
    }

    static func object<T: Codable>(from filename: String, extension type: String, bundle: Bundle) -> T {
        do {
            guard let url = bundle.url(forResource: filename, withExtension: type) else { fatalError() }
            let data = try Data(contentsOf: url)
            let jsonDecoder = JSONDecoder.IRJSONDecoder()
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            fatalError()
        }
    }

    static func arrayReponse<T: Codable>(from filename: String, extension type: String) -> T {
        return arrayReponse(from: filename, extension: type, bundle: Bundle(for: self))
    }

    static func arrayReponse<T: Codable>(from filename: String, extension type: String, bundle: Bundle) -> T {
        do {
            guard let url = bundle.url(forResource: filename, withExtension: type) else { fatalError() }
            let data = try Data(contentsOf: url)
            let jsonDecoder = JSONDecoder.IRJSONDecoder()
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            fatalError()
        }
    }
}
