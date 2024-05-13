//
//  AnySubscription.swift
//  IRCV
//
//  Created by Nuno Salvador on 16/06/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Combine

final class AnySubscription: Subscription {
    private let cancellable: Cancellable
    
    init(_ cancel: @escaping () -> Void) {
        cancellable = AnyCancellable(cancel)
    }
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        cancellable.cancel()
    }
}
