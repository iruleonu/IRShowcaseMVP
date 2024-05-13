//
//  IRErrors.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 23/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation

extension NSError {
    static func error(withMessage: String, statusCode: Int = 0) -> NSError {
        return NSError(domain: "com.iruleonu.error", code: statusCode, userInfo: [NSLocalizedDescriptionKey: withMessage])
    }
}
