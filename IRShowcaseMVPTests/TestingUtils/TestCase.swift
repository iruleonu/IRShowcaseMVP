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
        // We need to use the isRecording bool despite the deprecation warning
        let shouldRecordSnapshots = false
        isRecording = shouldRecordSnapshots
        withSnapshotTesting(
            record: shouldRecordSnapshots ? .all : .missing,
            diffTool: .default
        ) {
            super.setUp()
        }
    }
}
