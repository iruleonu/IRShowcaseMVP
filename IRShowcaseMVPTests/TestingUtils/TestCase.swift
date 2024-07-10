//
//  TestCase.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import XCTest
import SnapshotTesting
@testable import IRShowcaseMVP

class TestCase: XCTestCase {
    override func setUp() {
        withSnapshotTesting(
            record: SnapshotTestingConfiguration.Record.never,
            diffTool: SnapshotTestingConfiguration.DiffTool.default
        ) {
            super.setUp()
        }
    }
}
