//
//  DummyProductsView.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import SwiftUI

struct DummyProductsView : View {
    private let presenter: DummyProductsViewModel
    @ObservedObject private var viewModel: DummyProductsViewObservableObject

    init(presenter: DummyProductsViewModel) {
        self.presenter = presenter
        self.viewModel = presenter.observableObject
    }

    var body: some View {
        if viewModel.showErrorView {
            ErrorView(viewModel: viewModel)
        } else {
            ContentView(
                presenter: presenter,
                viewModel: viewModel
            )
        }
    }
}

private struct ContentView: View {
    let presenter: DummyProductsViewModel
    @ObservedObject var viewModel: DummyProductsViewObservableObject

    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    List($viewModel.dummyProducts, id: \.self, selection: $viewModel.selectedDummyProduct) { dummyProduct in
                        NavigationLink {
                            self.presenter.onDummyProductTap(dummyProduct: dummyProduct.wrappedValue)
                        } label: {
                            DummyProductCell(dummyProduct: dummyProduct.wrappedValue)
                        }
                    }
                }
            }
            .onAppear { self.presenter.onAppear() }
            .navigationBarTitle(Text(self.viewModel.navBarTitle))
        }
    }
}

private struct ErrorView: View {
    @ObservedObject var viewModel: DummyProductsViewObservableObject

    var body: some View {
        Text(viewModel.errorViewLabel)
    }
}

#if DEBUG
struct DummyProductsView_Previews : PreviewProvider {
    static var previews: some View {
        let network = APIServiceBuilder.make()
        let persistence = PersistenceLayerBuilder.make()
        let localDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: .localOnly,
            network: network,
            persistence: persistence
        )
        let remoteDataProvider: DataProvider<DummyProductDataContainer> = DataProviderBuilder.makeDataProvider(
            config: .remoteOnly,
            network: network,
            persistence: persistence
        )
        return DummyProductsScreenBuilder().make(
            localDataProvider: localDataProvider,
            remoteDataProvider: remoteDataProvider
        )
    }
}
#endif

