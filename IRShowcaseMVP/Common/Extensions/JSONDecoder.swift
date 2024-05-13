//
//  JSONDecoder.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 02/04/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation

public extension JSONDecoder {
    static func IRJSONDecoder() -> JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let formatter = DateFormatter()
            let locale = Locale(identifier: "en_US_POSIX")
            formatter.locale = locale
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            var date: Date?
            switch dateStr.count {
            case 10:
                formatter.timeZone = TimeZone(identifier: "UTC")
                formatter.dateFormat = "yyyy-MM-dd"
                date = formatter.date(from: dateStr)
            case 20...29:
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                date = formatter.date(from: dateStr)
                if date == nil {
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                    date = formatter.date(from: dateStr)
                }
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
            }
            guard let safeDate = date else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateStr)")
            }
            return safeDate
        })
        return jsonDecoder
    }
}
