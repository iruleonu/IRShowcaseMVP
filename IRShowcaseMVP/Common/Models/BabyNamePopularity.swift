//
//  BabyNamePopularity.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct BabyNamePopularity: Codable, Hashable {
    let yearOfBirth: Int
    let gender: Gender
    let ethnicity: String
    let name: String
    let numberOfBabiesWithSameName: Int
    let nameRank: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let yearOfBirth = try container.decode(Int.self, forKey: .yearOfBirth)
        let gender = try container.decode(Gender.self, forKey: .gender)
        let ethnicity = try container.decode(String.self, forKey: .ethnicity)
        let name = try container.decode(String.self, forKey: .name)
        let numberOfBabiesWithSameName = try container.decode(Int.self, forKey: .numberOfBabiesWithSameName)
        let nameRank = try container.decode(Int.self, forKey: .nameRank)
        self.init(yearOfBirth: yearOfBirth, gender: gender, ethnicity: ethnicity, name: name, numberOfBabiesWithSameName: numberOfBabiesWithSameName, nameRank: nameRank)
    }

    init(
        yearOfBirth: Int,
        gender: Gender,
        ethnicity: String,
        name: String,
        numberOfBabiesWithSameName: Int,
        nameRank: Int
    ) {
        self.yearOfBirth = yearOfBirth
        self.gender = gender
        self.ethnicity = ethnicity
        self.name = name
        self.numberOfBabiesWithSameName = numberOfBabiesWithSameName
        self.nameRank = nameRank
    }
}

extension BabyNamePopularity: Equatable {
    static func == (left: BabyNamePopularity, right: BabyNamePopularity) -> Bool {
        return left.yearOfBirth == right.yearOfBirth
        && left.gender == right.gender
        && left.ethnicity == right.ethnicity
        && left.name == right.name
        && left.numberOfBabiesWithSameName == right.numberOfBabiesWithSameName
        && left.nameRank == right.nameRank
    }
}
