//
//  Service.swift
//  IRShowcase
//
//  Created by Nuno Salvador on 21/03/2019.
//  Copyright © 2019 Nuno Salvador. All rights reserved.
//

import Foundation
import UIKit

protocol AppService {
    /// Called on all services after didFinishLaunchingWithOptions is complete.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
}
