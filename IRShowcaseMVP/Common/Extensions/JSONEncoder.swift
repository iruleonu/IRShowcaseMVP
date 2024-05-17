//
//  JSONEncoder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

extension JSONEncoder {
    static func encode<T: Encodable>(from data: T) {
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let json = try jsonEncoder.encode(data)
            guard let jsonString = String(data: json, encoding: .utf8) else { return }
            FileManager.saveStringToDocumentDirectory(jsonString, filename: "Output.json")
        } catch {
            print(error.localizedDescription)
        }
    }

    static func encodeObjectToString<T: Encodable>(from data: T, filename: String) -> (String?, Error?) {
        var auxString: String?
        var auxError: Error?
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            let json = try jsonEncoder.encode(data)
            guard let jsonString = String(data: json, encoding: .utf8) else {
                return (nil, EncodingError.invalidValue("", .init(codingPath: [], debugDescription: "")))
            }
            auxString = jsonString
        } catch {
            auxError = error
        }
        return (auxString, auxError)
    }
}
