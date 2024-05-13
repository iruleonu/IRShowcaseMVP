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
            saveToDocumentDirectory(jsonString)
        } catch {
            print(error.localizedDescription)
        }
    }

    static private func saveToDocumentDirectory(_ jsonString: String) {
        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = path.appendingPathComponent("Output.json")

        do {
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }

    }
}
