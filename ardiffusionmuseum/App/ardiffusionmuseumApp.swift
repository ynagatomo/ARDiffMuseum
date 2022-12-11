//
//  ardiffusionmuseumApp.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/06.
//

import SwiftUI

@main
struct ARDiffusionMuseumApp: App {
    @StateObject private var imageGenerator = ImageGenerator()

    var body: some Scene {
        WindowGroup {
            ImgGenView(imageGenerator: imageGenerator)
        }
    }
}
