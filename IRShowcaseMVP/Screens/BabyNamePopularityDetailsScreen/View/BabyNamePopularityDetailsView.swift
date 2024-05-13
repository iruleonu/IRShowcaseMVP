//
//  BabyNamePopularityDetailsView.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import SwiftUI

struct BabyNamePopularityDetailsView : View {
    private let presenter: BabyNamePopularityDetailsPresenter
    @ObservedObject private var viewModel: BabyNamePopularityDetailsViewModel

    init(presenter: BabyNamePopularityDetailsPresenter) {
        self.presenter = presenter
        self.viewModel = presenter.viewModel
    }

    var body: some View {
        NavigationView {
            List {
                ContentView(
                    yearOfBirth: $viewModel.yearOfBirth,
                    name: $viewModel.name,
                    rank: $viewModel.nameRank
                )
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .onAppear { self.presenter.onAppear() }
            .navigationBarTitle(Text("Baby name details"))
        }
    }
}

private struct ContentView: View {
    @Binding var yearOfBirth: String
    @Binding var name: String
    @Binding var rank: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Name: ")
                    .font(.headline)
                Text(name)
                    .font(.subheadline)
            }
            HStack {
                Text("Year of birth: ")
                    .font(.headline)
                Text(yearOfBirth)
                    .font(.subheadline)
            }
            HStack {
                Text("Name rank: ")
                    .font(.headline)
                Text(rank)
                    .font(.subheadline)
            }
        }
    }
}

#if DEBUG
struct BabyNamePopularityDetailsView_Previews : PreviewProvider {
    static var previews: some View {
        return BabyNamePopularityDetailsScreenBuilder().make(
            babyNamePopularity: .init(
                yearOfBirth: 2016,
                gender: .female,
                ethnicity: "ASIAN AND PACIFIC ISLANDER",
                name: "Olivia",
                numberOfBabiesWithSameName: 172,
                nameRank: 1
            )
        )
    }
}
#endif

