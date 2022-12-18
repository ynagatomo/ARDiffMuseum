//
//  ImageGenerator.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/08.
//

import UIKit
import StableDiffusion
import CoreML

@MainActor
final class ImageGenerator: NSObject, ObservableObject {
    struct GenerationParameter {
        let prompt: String
        let seed: Int
        let stepCount: Int
        let imageCount: Int
        let disableSafety: Bool
    }

    struct GeneratedImages {
        let parameter: GenerationParameter
        let images: [UIImage]
    }

    enum GenerationState {
        case idle       // idling
        case generating // generating images
        case saving     // saving images into Photo Library
    }

    @Published var generationState: GenerationState = .idle
    @Published var generatedImages: GeneratedImages?
    @Published var progressStep: (step: Int, stepCount: Int) = (0, 0) // (step, stepCount)

    private var sdPipeline: StableDiffusionPipeline?
    private var savingImageCount = 0
    private var savedImageCount = 0

    //    func removeSDPipeline() {
    //        sdPipeline = nil    // to reduce memory consumption :(
    //    }

    private func setState(_ state: GenerationState) { // for actor isolation
        generationState = state
    }

    func setPipeline(_ pipeline: StableDiffusionPipeline) { // for actor isolation
        sdPipeline = pipeline
    }

    private func setGeneratedImages(_ images: GeneratedImages) { // for actor isolation
        generatedImages = images
    }

    private func setProgressStep(step: Int, stepCount: Int) {
        progressStep = (step, stepCount)
    }
}

// MARK: - Stable Diffusion

extension ImageGenerator {
    // swiftlint:disable function_body_length
    func generateImages(of param: GenerationParameter, enableStableDiffusion: Bool) {
        guard generationState == .idle else { return }

        if enableStableDiffusion {
            if param.prompt == "" { return }

            Task.detached(priority: .high) {
                await self.setState(.generating)

                if await self.sdPipeline == nil {

                    // Create the StableDiffusionPipeline

                    guard let path = Bundle.main.path(forResource: "CoreMLModels", ofType: nil, inDirectory: nil) else {
                        fatalError("IG: Fatal error: failed to find the CoreML models.")
                    }
                    let resourceURL = URL(fileURLWithPath: path)

                    let config = MLModelConfiguration()
                    if !ProcessInfo.processInfo.isiOSAppOnMac {
                        config.computeUnits = .cpuAndGPU
                    }
                    debugLog("IG: creating StableDiffusionPipeline object... resosurceURL = \(resourceURL)")

                    // reduceMemory option was added at v0.1.0
                    // On iOS, the reduceMemory option should be set to true
                    let reduceMemory = ProcessInfo.processInfo.isiOSAppOnMac ? false : true
                    if let pipeline = try? StableDiffusionPipeline( resourcesAt: resourceURL,
                                                                    configuration: config, reduceMemory: reduceMemory) {
                        await self.setPipeline(pipeline)
                    } else {
                        fatalError("IG: Fatal error: failed to create the Stable-Diffusion-Pipeline.")
                    }
                }

                if let sdPipeline = await self.sdPipeline {

                    // Generate images

                    do {
                        debugLog("IG: generating images...")
                        await self.setProgressStep(step: 0, stepCount: param.stepCount)
                        let cgImages = try sdPipeline.generateImages(prompt: param.prompt,
                                                                     imageCount: param.imageCount,
                                                                     stepCount: param.stepCount,
                                                                     seed: param.seed,
                                                                     disableSafety: param.disableSafety,
                                                                     progressHandler: self.progressHandler)
                        debugLog("IG: images were generated.")
                        let uiImages = cgImages.compactMap { image in
                            if let cgImage = image { return UIImage(cgImage: cgImage)
                            } else { return nil }
                        }
                        await self.setGeneratedImages(GeneratedImages(parameter: param, images: uiImages))
                    } catch {
                        debugLog("IG: failed to generate images.")
                    }
                }

                await self.setState(.idle)
            }
        } else {
            // Stable Diffusion is disable. Create sample images.
            let images = GeneratedImages(parameter: GenerationParameter(prompt: "", seed: 0, stepCount: 0,
                                                                        imageCount: AppConstant.sampleImageNames.count,
                                                                        disableSafety: false),
                                         images: AppConstant.sampleImageNames.map { UIImage(named: $0)! })
            setGeneratedImages(images)
        }
    }

    nonisolated func progressHandler(progress: StableDiffusionPipeline.Progress) -> Bool {
        debugLog("IG: Progress: step / stepCount = \(progress.step) / \(progress.stepCount)")

        if ProcessInfo.processInfo.isiOSAppOnMac {
            let generatedImages = GeneratedImages(parameter: GenerationParameter(prompt: progress.prompt,
                                                 seed: 0,
                                                 stepCount: progress.stepCount,
                                                 imageCount: progress.currentImages.count,
                                                 disableSafety: progress.isSafetyEnabled),
                                                 images: progress.currentImages.compactMap {
                if let cgImage = $0 {
                    return UIImage(cgImage: cgImage)
                } else {
                    return nil
                }
            })

            DispatchQueue.main.async {
                self.setGeneratedImages(generatedImages)
                self.setProgressStep(step: progress.step, stepCount: progress.stepCount)
            }
        } else {
            DispatchQueue.main.async {
                self.setProgressStep(step: progress.step, stepCount: progress.stepCount)
            }
        }

        return true // continue
    }
}

// MARK: - Save images in the Photo Library

extension ImageGenerator {
    func saveImagesIntoPhotoLibrary(images: [UIImage]) {
        guard generationState == .idle else { return }

        savingImageCount = images.count
        savedImageCount = 0
        generationState = .saving
        images.forEach { image in
            saveImageIntoPhotoLibrary(image: image)
        }
    }

    private func saveImageIntoPhotoLibrary(image: UIImage) {
        // Adds the specified image to the user’s Camera Roll album.
        UIImageWriteToSavedPhotosAlbum(image, // UIImage
                                       self,  // completionTarget
                                       #selector(didFinishSaving), // completionSelector
                                       nil) // contextInfo
    }

    @objc func didFinishSaving(_ image: UIImage, didFinishSavingWithError error: Error?,
                               contextInfo: UnsafeRawPointer) {
        assert(generationState == .saving)

        savedImageCount += 1 // including errors
        if savedImageCount == savingImageCount {
            generationState = .idle
        }

        if let error {
            debugLog("GEN: Error: failed to save an image to Camera Roll album.")
            debugLog(" - \(error.localizedDescription)")
        } else {
            debugLog("GEN: completed saving an image into Photo Library.")
        }
    }
}
