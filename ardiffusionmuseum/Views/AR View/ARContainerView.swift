//
//  ARContainerView.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/06.
//

import SwiftUI

struct ARContainerView: UIViewControllerRepresentable {
    let images: [UIImage]
    let pictureFrameIndex: Int
    let arDebugOptionOn: Bool
    let peopleOcclusionOn: Bool
    let objectOcclusionOn: Bool
    let intervalTime: Double

    func makeUIViewController(context: Context) -> ARViewController {
        let arViewController = ARViewController()
        arViewController.setImages(images)
        arViewController.setOptions(arDebugOptionOn: arDebugOptionOn,
                                    peopleOcclusionOn: peopleOcclusionOn,
                                    objectOcclusionOn: objectOcclusionOn,
                                    intervalTime: intervalTime)
        return arViewController
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        uiViewController.update(pictureFrameIndex: pictureFrameIndex)
    }
}

//    struct ARContainerView_Previews: PreviewProvider {
//        static var previews: some View {
//            ARContainerView()
//        }
//    }
