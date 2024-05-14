//
//  ResourceTests.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import XCTest

@testable import IRShowcaseMVP

class ResourceTests: XCTestCase {
    func testEqualityForSameResource() {
        let resource1 = Resource.babyNamePopularities
        let resource2 = Resource.babyNamePopularities
        XCTAssertEqual(resource1, resource2)
    }

    func testInequalityForDifferentResource() {
        let resource1 = Resource.unknown
        let resource2 = Resource.babyNamePopularities
        XCTAssertNotEqual(resource1, resource2)
        XCTAssertNotEqual(resource2, resource1)
    }
}