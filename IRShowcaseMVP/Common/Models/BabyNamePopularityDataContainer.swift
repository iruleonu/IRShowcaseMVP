//
//  BabyNamePopularityDataContainer.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 14/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct BabyNamePopularityDataContainer: Codable, Hashable {
    let data: [[String]]

    enum CodingKeys: String, CodingKey {
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode([FailableDecodableArray<String>].self, forKey: .data)
        self.init(data: data.compactMap({ $0.elements }))
    }

    init(data: [[String]]) {
        self.data = data
    }
}

extension BabyNamePopularityDataContainer: Equatable {
    static func == (left: BabyNamePopularityDataContainer, right: BabyNamePopularityDataContainer) -> Bool {
        return left.data == right.data
    }
}

extension BabyNamePopularityDataContainer {
    var babyNamePopularityRepresentation: [BabyNamePopularity] {
        var aux: Set<BabyNamePopularity> = Set()

        for elem in self.data {
            aux.insert(
                BabyNamePopularity(
                    yearOfBirth: Int(elem[4])!,
                    gender: Gender(rawValue: elem[5]) ?? .unknown,
                    ethnicity: elem[6],
                    name: elem[7],
                    numberOfBabiesWithSameName: Int(elem[8])!,
                    nameRank: Int(elem[9])!
                )
            )
        }

        return Array(aux)
    }
}
