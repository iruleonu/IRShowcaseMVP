//
//  XCTestCase+Snapshots.swift
//  IRShowcaseMVPTests
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import UIKit
import XCTest
import SwiftUI
import SnapshotTesting
@testable import IRShowcaseMVP

extension XCTestCase {
    /// Take snapshots in several devices. Recommended for full screen views to validate it looks fine in multiple devices.
    func cwSnapshotOnDevices<Content>(
        view: Content,
        wait: TimeInterval = 0,
        testName: String = #function,
        file: StaticString = #file
    ) where Content: View {
        snapshotOnSelectedDevice(
            view: view,
            file: file,
            testName: testName,
            deviceName: "iPhoneSE",
            viewConfig: ViewImageConfig.iPhoneSe
        )

        snapshotOnSelectedDevice(
            view: view,
            file: file,
            testName: testName,
            deviceName: "iPhoneX",
            viewConfig: ViewImageConfig.iPhoneX
        )

        snapshotOnSelectedDevice(
            view: view,
            file: file,
            testName: testName,
            deviceName: "iPadPro12.9.portrait",
            viewConfig: ViewImageConfig.iPadPro12_9(.portrait)
        )
    }

    func cwSnapshotOnMax<Content>(
        view: Content,
        wait: TimeInterval = 0,
        testName: String = #function,
        file: StaticString = #file
    ) where Content: View {
        // Snapshot `iPhoneXsMax`:
        snapshotOnSelectedDevice(
            view: view,
            file: file,
            testName: testName,
            deviceName: "iPhoneXsMax",
            viewConfig: ViewImageConfig.iPhoneXsMax
        )
    }

    func cwSnapshotScrollView<Content>(
        view: Content,
        height: CGFloat = 1000,
        testName: String = #function,
        file: StaticString = #file
    ) where Content: View {
        let configurations: [(screen: ViewImageConfig, name: String)] = {
            return [
                (screen: .iPhoneSe(.portrait), name: "iPhoneSE"),
                (screen: .iPhoneX(.portrait), name: "iPhoneX"),
                (screen: .iPadPro12_9(.portrait), name: "iPadPro.portrait")
            ]
        }()

        func customViewConfigWithModifiedHeight(_ original: ViewImageConfig) -> ViewImageConfig {
            ViewImageConfig(
                safeArea: original.safeArea,
                size: .init(width: original.size!.width, height: height),
                traits: .init()
            )
        }
        configurations
            .forEach({ configuration in
                snapshotOnSelectedDevice(
                    view: view,
                    file: file,
                    testName: testName,
                    deviceName: configuration.name,
                    viewConfig: customViewConfigWithModifiedHeight(configuration.screen)
                )
            })
    }

    /// Take a snapshot at the size of the view. Recommended for isolated UI components like a Button.
    func cwSnapshot<Content>(
        view: Content,
        wait: TimeInterval = 0,
        testName: String = #function,
        file: StaticString = #file
    ) where Content: View {
        assertSnapshot(
            matching: UIHostingController(rootView: view).rootView,
            as: .wait(for: wait, on: .image),
            file: file,
            testName: testName
        )
    }
}

private extension XCTestCase {
    func snapshotOnSelectedDevice<Content>(
       view: Content,
       wait: TimeInterval = 0,
       file: StaticString,
       testName: String,
       deviceName: String,
       viewConfig: ViewImageConfig
   ) where Content: View {
       assertSnapshot(
        of: view,
        as: .image(
            drawHierarchyInKeyWindow: false,
            precision: 1,
            perceptualPrecision: 1,
            layout: .device(config: viewConfig),
            traits: .init()
        ),
        named: deviceName,
        file: file,
        testName: testName
       )
   }
}
