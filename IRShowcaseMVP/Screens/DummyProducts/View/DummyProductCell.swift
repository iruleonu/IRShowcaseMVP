//
//  DummyProductCell.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation
import SwiftUI

struct DummyProductCell: View {
    @State private var selection: String?
    var dummyProduct: DummyProduct

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: URL(string: "")) { phase in
                switch phase {
                case .failure:
                    Image("placeholder")
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    if dummyProduct.imageBasedOnProductRating.count == 0 {
                        Image("placeholder")
                    } else {
                        ProgressView()
                    }
                }
            }
            .frame(width: 124, height: 124)
            .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text("Name: ")
                        .font(.headline)

                    Text(dummyProduct.title)
                        .foregroundColor(.primary)
                        .font(.subheadline)
                }

                HStack(alignment: .bottom) {
                    Text("Rating:")
                        .font(.headline)

                    Text(String(dummyProduct.rating))
                        .foregroundColor(.primary)
                        .font(.subheadline)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
    }
}

#if DEBUG
struct DummyProductCell_Previews: PreviewProvider {
    static var previews: some View {
        return DummyProductCell(
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
