//
//  RandomNameSelectorView.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 12/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import SwiftUI

struct RandomNameSelectorView : View {
    private let presenter: RandomNameSelectorPresenter
    @ObservedObject private var viewModel: RandomNameSelectorViewModel

    init(presenter: RandomNameSelectorPresenter) {
        self.presenter = presenter
        self.viewModel = presenter.viewModel
    }

    var body: some View {
        if viewModel.showErrorView {
            ErrorView()
        } else {
            ContentView(
                presenter: presenter,
                viewModel: viewModel
            )
        }
    }
}

private struct ContentView: View {
    let presenter: RandomNameSelectorPresenter
    @ObservedObject var viewModel: RandomNameSelectorViewModel

    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    ButtonsContainerView {
                        self.presenter.onFemaleButtonTap()
                        if let selected = viewModel.selectedBabyNamePopularity {
                            proxy.scrollTo(selected)
                        }
                    } onRandomButtonTapAction: {
                        self.presenter.onRandomButtonTap()
                        if let selected = viewModel.selectedBabyNamePopularity {
                            proxy.scrollTo(selected)
                        }
                    }
                    onMaleButtonTapAction: {
                        self.presenter.onMaleButtonTap()
                        if let selected = viewModel.selectedBabyNamePopularity {
                            proxy.scrollTo(selected)
                        }
                    }

                    List($viewModel.babyNamePopularities, id: \.self, selection: $viewModel.selectedBabyNamePopularity) { babyNamePopularity in
                        NavigationLink {
                            self.presenter.navigateToBabyNamePopularityDetails(babyNamePopularity: babyNamePopularity.wrappedValue)
                        } label: {
                            BabyPopularNameCell(babyNamePopularity: babyNamePopularity.wrappedValue)
                        }
                    }
                }
                Text("\(viewModel.selectedBabyNamePopularity?.name ?? "N/A")")
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .onAppear { self.presenter.onAppear() }
            .navigationBarTitle(Text(self.viewModel.navBarTitle))
        }
    }
}

private struct ErrorView: View {
    var body: some View {
        Text("No data")
    }
}

private struct ButtonsContainerView: View {
    let onFemaleButtonTapAction: () -> Void
    let onRandomButtonTapAction: () -> Void
    let onMaleButtonTapAction: () -> Void

    var body: some View {
        VStack() {
            Text("Tap on a gender and then tap on 'Random pick' to choose a name randomly with that gender")
                .font(.headline)
                .padding([.leading, .trailing], 15)
                .padding(.top, 15)

            HStack(spacing: 30) {
                Button("Female") {
                    onFemaleButtonTapAction()
                }
                .buttonStyle(.borderedProminent)

                Button("Random pick") {
                    onRandomButtonTapAction()
                }
                .buttonStyle(.borderedProminent)

                Button("Male") {
                    onMaleButtonTapAction()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 5)
            .padding(.bottom, 15)
            .frame(maxWidth: .infinity)
        }
    }
}

#if DEBUG
struct RandomNameSelectorView_Previews : PreviewProvider {
    static var previews: some View {
        let dataProvider: DataProvider<[BabyNamePopularity]> = DataProviderBuilder.makeDataProvider(
            config: .localOnly,
            network: APIServiceBuilder.make(),
            persistence: PersistenceLayerBuilder.make()
        )
        return RandomNameSelectorScreenBuilder().make(dataProvider: dataProvider)
    }
}
#endif

