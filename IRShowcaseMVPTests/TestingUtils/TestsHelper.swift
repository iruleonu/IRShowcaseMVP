//
//  TestsHelper.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 22/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

struct TestsHelper {
    static func sleepTask(_ duration: Float = 1.0) -> Task<Void, Never> {
        let sleepTask: Task<Void, Never> = .init {
            let sleep: Task<Void, Never> = .init {
                let duration = UInt64(duration * 1_000_000_000)
                try? await Task.sleep(nanoseconds: duration)
            }
            await withTaskCancellationHandler {
                @Sendable () -> () in await sleep.value
            }
            onCancel: {
                sleep.cancel()
            }
        }
        return sleepTask
    }
}
