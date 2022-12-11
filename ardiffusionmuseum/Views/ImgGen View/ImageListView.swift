//
//  ImageListView.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/11.
//

import SwiftUI

struct ImageListView: View {
    let images: [UIImage]?

    var body: some View {
        VStack {
            if let images {
                    Color.clear
                        .padding(.top, 50)

                    ForEach(images, id: \.self) {
                        Image(uiImage: $0)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: AppConstant.imageDisplayMaxWidth)
                    }

                    Color.clear
                        .padding(.top, 100)
            } else {
                Color.clear
                    .padding(.top, 50)
                Text("no image")
                    .frame(maxWidth: AppConstant.imageDisplayMaxWidth)
            }
        } // VStack
    }
}

struct ImageListView_Previews: PreviewProvider {
    static let images: [UIImage] = [UIImage(named: "sample1")!]

    static var previews: some View {
        ImageListView(images: images)
    }
}
