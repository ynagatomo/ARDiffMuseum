//
//  ARContentView.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/06.
//

import SwiftUI

struct ARContentView: View {
    @Environment(\.dismiss) private var dismiss

    let images: [UIImage]
    let arDebugOptionOn: Bool
    let peopleOcclusionOn: Bool
    let objectOcclusionOn: Bool
    let intervalTime: Double

    var body: some View {
        ARContainerView(images: images,
                        pictureFrameIndex: 0,
                        arDebugOptionOn: arDebugOptionOn,
                        peopleOcclusionOn: peopleOcclusionOn,
                        objectOcclusionOn: objectOcclusionOn,
                        intervalTime: intervalTime)
            .ignoresSafeArea()
            .overlay {
                VStack {
                    HStack {
                        Text("Face the wall to display the image.")
                            .foregroundColor(.green)
                        Spacer()
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 32))
                        }
                    }
                    .padding()
                    Spacer()
                }
            }
    }
}

struct ARContentView_Previews: PreviewProvider {
    static var previews: some View {
        ARContentView(images: [],
                      arDebugOptionOn: false,
                      peopleOcclusionOn: false,
                      objectOcclusionOn: false,
                      intervalTime: 5.0)
    }
}
