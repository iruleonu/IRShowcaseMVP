//
//  DummyProduct.swift
//  IRShowcaseMVP
//
//  Created by Nuno Salvador on 16/05/2024.
//  Copyright © 2024 Nuno Salvador. All rights reserved.
//

import Foundation

struct DummyProduct: Codable, Hashable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let price: Int
    let discountPercentage: Float
    let rating: Float
    let stock: Float
    let brand: String
    let category: String
    let thumbnail: String
    let images: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(Int.self, forKey: .id)
        let title = try container.decode(String.self, forKey: .title)
        let description = try container.decode(String.self, forKey: .description)
        let price = try container.decode(Int.self, forKey: .price)
        let discountPercentage = try container.decode(Float.self, forKey: .discountPercentage)
        let rating = try container.decode(Float.self, forKey: .rating)
        let stock = try container.decode(Float.self, forKey: .stock)
        let brand = try container.decode(String.self, forKey: .brand)
        let category = try container.decode(String.self, forKey: .category)
        let thumbnail = try container.decode(String.self, forKey: .thumbnail)
        let images = try container.decode([String].self, forKey: .images)
        self.init(
            id: id, 
            title: title,
            description: description,
            price: price,
            discountPercentage: discountPercentage,
            rating: rating,
            stock: stock,
            brand: brand,
            category: category,
            thumbnail: thumbnail,
            images: images
        )
    }

    init(
        id: Int,
        title: String,
        description: String,
        price: Int,
        discountPercentage: Float,
        rating: Float,
        stock: Float,
        brand: String,
        category: String,
        thumbnail: String,
        images: [String]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.discountPercentage = discountPercentage
        self.rating = rating
        self.stock = stock
        self.brand = brand
        self.category = category
        self.thumbnail = thumbnail
        self.images = images
    }
}

extension DummyProduct: Equatable {
    static func == (left: DummyProduct, right: DummyProduct) -> Bool {
        return left.id == right.id
        && left.title == right.title
        && left.description == right.description
        && left.price == right.price
        && left.discountPercentage == right.discountPercentage
        && left.rating == right.rating
        && left.stock == right.stock
        && left.brand == right.brand
        && left.category == right.category
        && left.thumbnail == right.thumbnail
        && left.images == right.images
    }
}

extension DummyProduct {
    var imageBasedOnProductRating: String {
        // Choose the image based on the product rating
        // *note: Looking at the remote data it looks like the latest image of the array is the same as the thumbnail
        // So we're assuming highest rated images appears first on the images array

        var selectedImageUrl: String?

        var imagesToDrop = 0
        if rating > 4 {
            imagesToDrop = 0
        } else if rating >= 3 && rating <= 4 {
            imagesToDrop = 1
        } else {
            imagesToDrop = 2
        }

        selectedImageUrl = images.dropFirst(imagesToDrop).first
        while selectedImageUrl == nil && imagesToDrop > 0 {
            imagesToDrop -= 1
            selectedImageUrl = images.dropFirst(imagesToDrop).first
        }

        return selectedImageUrl ?? thumbnail
    }

    private func selectImage() {

    }
}
