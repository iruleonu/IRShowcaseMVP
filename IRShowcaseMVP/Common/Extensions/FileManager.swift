//
//  FileManager.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

extension FileManager {
    static func saveStringToDocumentDirectory(_ jsonString: String, filename: String) {
        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = path.appendingPathComponent(filename)

        do {
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
    }

    static func object<T: Codable>(from filename: String) -> T? {
        do {
            guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
            let fileURL = path.appendingPathComponent(filename)
            let data = try Data(contentsOf: fileURL)
            let jsonDecoder = JSONDecoder.IRJSONDecoder()
            return try? jsonDecoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}
