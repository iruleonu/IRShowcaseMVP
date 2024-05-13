//
//  BabyPopularNameCell.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 13/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI

struct BabyPopularNameCell: View {
    @State private var selection: String?
    var babyNamePopularity: BabyNamePopularity

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(babyNamePopularity.name)
                .foregroundColor(.primary)
                .font(.subheadline)
        }
    }
}

#if DEBUG
struct BabyPopularNameCell_Previews: PreviewProvider {
    static var previews: some View {
        let babyNamePopularity = BabyNamePopularity(
            yearOfBirth: 2016,
            gender: .female,
            ethnicity: "ASIAN AND PACIFIC ISLANDER",
            name: "Olivia",
            numberOfBabiesWithSameName: 172,
            nameRank: 1
        )
        return BabyPopularNameCell(babyNamePopularity: babyNamePopularity)
    }
}
#endif
