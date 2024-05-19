//
//  DummyProductsView.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import SwiftUI

struct DummyProductsView : View {
    private let viewModel: DummyProductsViewModel
    @ObservedObject private var observableObject: DummyProductsViewObservableObject

    init(viewModel: DummyProductsViewModel) {
        self.viewModel = viewModel
        self.observableObject = viewModel.observableObject
    }

    var body: some View {
        if observableObject.showErrorView {
            ErrorView(label: $observableObject.errorViewLabel)
        } else {
            ContentView(
                viewModel: viewModel,
                observableObject: observableObject
            )
        }
    }
}

private struct ContentView: View {
    let viewModel: DummyProductsViewModel
    @ObservedObject var observableObject: DummyProductsViewObservableObject

    var body: some View {
        NavigationView {
            VStack {
                ScrollViewReader { proxy in
                    List($observableObject.dummyProducts, id: \.self, selection: $observableObject.selectedDummyProduct) { dummyProduct in
                        NavigationLink {
                            self.viewModel.onDummyProductTap(dummyProduct: dummyProduct.wrappedValue)
                        } label: {
                            DummyProductCell(dummyProduct: dummyProduct.wrappedValue)
                        }
                        .onAppear {
                            self.viewModel.onItemAppear(dummyProduct.wrappedValue)
                        }
                    }
                    if observableObject.pagingState.isFetching {
                        ProgressView()
                    }
                }
            }
            .onAppear { self.viewModel.onAppear() }
            .navigationBarTitle(Text(self.observableObject.navBarTitle))
        }
    }
}

private struct ErrorView: View {
    @Binding var label: String

    var body: some View {
        Text(label)
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

