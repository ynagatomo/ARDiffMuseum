//
//  AppConstant.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/08.
//

import Foundation

struct AppConstant {
    // Stable Diffusion version
    // - This is used only to display the version string.
    static let stableDiffusionVersion = "2.0"

    // Note: Add any prompts as you like.
    // swiftlint:disable line_length
    static let registeredPrompts = [
        "",     // 1st prompt should be empty ("")
        "futuristic Tokyo with white glass domes, tress, crowded places, sunrise, great glass buildings, shops, hotels, concept city art, detailed, hq, hyperdetailed, artstation, cgsociety, 8 k",
        "mushrooms growing on a lost spaceship floating through the universe, 8k high definition digital art, trending on artstation",
        "a portrait of woman. realist abstract. key art. cyberpunk, blue and pink, intricate artwork. 8 k octane render, trending on artstation, very coherent symmetrical artwork. cinematic, hyperrealism, very detailed, iridescent accents"
    ]

    static let defaultNegativePrompt =
"""
lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, multiple legs, malformation
"""

    // Layout
    static let imageDisplayMaxWidth: CGFloat = 600

    // Keys for @AppStorage (saved in UserDefaults)
    static let keyARDebugOptionOn = "keyARDebugOptionOn"
    static let keyStableDiffusionOn = "keyStableDiffusionOn"
    static let keyPeopleOcclusionOn = "keyPeopleOcclusionOn"
    static let keyObjectOcclusionOn = "keyObjectOcclusionOn"
    static let keyIntervalTime = "keyIntervalTime"

    // Sample Image Names in app bundle.
    static let sampleImageNames = [
        "sample1", "sample2", "sample3", "sample4"
    ]

    // Picture Frame Spec
    struct PictureFrameSpec {
        let modelName: String   // USDZ model name (wo ext)
        let enableVisualEffect: Bool
    }

    // Note: Add or replace picture frame USDZ model as you like
    static let pictureFrameSpecs = [
        PictureFrameSpec(modelName: "frame1",  // USDZ model name
                        enableVisualEffect: false)
    ]

    // AR Render-loopb
    static let scaleChangeIntervalTime: Double = 1.0 // [sec]
}
