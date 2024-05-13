//
//  Bundle.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 20/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation

public extension Bundle {
    var buildVersion: String {
        return (self.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
    }
}
