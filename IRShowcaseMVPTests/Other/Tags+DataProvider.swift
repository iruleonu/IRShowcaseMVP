//
//  Tags+DataProvider.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 21/06/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Testing

extension Tag {
    @Tag static var dataProvider: Self
    @Tag static var localDataProviderConfig: Self
    @Tag static var localFirstThenRemoteDataProviderConfig: Self
    @Tag static var localOnErrorUseRemoteDataProviderConfig: Self
    @Tag static var remoteDataProviderConfig: Self
    @Tag static var remoteFirstThenLocalDataProviderConfig: Self
    @Tag static var remoteOnErrorUseLocalDataProviderConfig: Self
    @Tag static var fetchStuff: Self
    @Tag static var fetchStuffPublisher: Self
}
