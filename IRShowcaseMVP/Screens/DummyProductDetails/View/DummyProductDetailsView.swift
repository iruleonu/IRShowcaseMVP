//
//  DummyProductDetailsView.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import SwiftUI

struct DummyProductDetailsView : View {
    private let viewModel: DummyProductDetailsViewModel
    @ObservedObject private var observableObject: DummyProductDetailsViewObservableObject

    init(viewModel: DummyProductDetailsViewModel) {
        self.viewModel = viewModel
        self.observableObject = viewModel.observableObject
    }

    var body: some View {
        NavigationView {
            List {
                ContentView(
                    imageBasedOnProductRating: $observableObject.imageBasedOnProductRating,
                    price: $observableObject.price,
                    discountPercentage: $observableObject.discountPercentage,
                    stock: $observableObject.stock,
                    rating: $observableObject.rating
                )
                .padding(.all, 15)
            }
            .onAppear { self.viewModel.onAppear() }
            .navigationBarTitle(self.observableObject.title)
        }
    }
}

private struct ContentView: View {
    @Binding var imageBasedOnProductRating: String
    @Binding var price: String
    @Binding var discountPercentage: String
    @Binding var stock: String
    @Binding var rating: String

    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: imageBasedOnProductRating)) { phase in
                switch phase {
                case .failure:
                    Image("placeholder")
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    if imageBasedOnProductRating.count == 0 {
                        Image("placeholder")
                    } else {
                        ProgressView()
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 10))
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)

            HStack {
                Text("Price: ")
                    .font(.headline)
                Text(price)
                    .font(.subheadline)
            }
            HStack {
                Text("Discount percentage: ")
                    .font(.headline)
                Text(discountPercentage)
                    .font(.subheadline)
            }
            HStack {
                Text("Stock: ")
                    .font(.headline)
                Text(stock)
                    .font(.subheadline)
            }
            HStack {
                Text("Rating: ")
                    .font(.headline)
                Text(rating)
                    .font(.subheadline)
            }
        }
    }
}

#if DEBUG
struct DummyProductDetailsView_Previews : PreviewProvider {
    static var previews: some View {
        return DummyProductDetailsScreenBuilder().make(
            dummyProduct: .init(
                id: 2,
                title: "iPhone X",
                description: "desc",
                price: 899,
                discountPercentage: 17.94,
                rating: 4.44,
                stock: 34,
                brand: "Apple",
                category: "smartphones",
                thumbnail: "https://cdn.dummyjson.com/product-images/2/thumbnail.jpg",
                images: ["https://cdn.dummyjson.com/product-images/2/1.jpg", "https://cdn.dummyjson.com/product-images/2/2.jpg", "https://cdn.dummyjson.com/product-images/2/3.jpg", "https://cdn.dummyjson.com/product-images/2/thumbnail.jpg"]
            )
        )
    }
}
#endif

