//
//  APIServiceBuilder.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct APIServiceBuilder {
    static func make() -> APIServiceImpl {
        return APIServiceImpl()
    }
}
