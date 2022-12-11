//
//  ImgGenView.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/06.
//

import SwiftUI

struct ImgGenView: View {
    @ObservedObject var imageGenerator: ImageGenerator

    @AppStorage(AppConstant.keyARDebugOptionOn) var arDebugOptionOn = true
    @AppStorage(AppConstant.keyStableDiffusionOn) var stableDiffusionOn = true
    @AppStorage(AppConstant.keyPeopleOcclusionOn) var peopleOcclusionOn = false
    @AppStorage(AppConstant.keyObjectOcclusionOn) var objectOcclusionOn = false
    @AppStorage(AppConstant.keyIntervalTime) var intervalTime: Double = 5.0

    @State private var showingSettings = false
    @State private var showingAR = false
    @State private var showingGenPanel = false

    struct GenParameter {
        var prompt: String = ""
        var imageCount: Int = 1
        var stepCount: Double = 20
        var seed: Double = 100
        var randomSeed = true
    }

    @State private var genParameter = GenParameter()
    @State private var willGenerate = false

    private var isGeneratorIdle: Bool {
        imageGenerator.generationState == .idle
    }

    private var imageExists: Bool {
        imageGenerator.generatedImages != nil
    }

    var body: some View {
        ZStack {
            Color("HomeBGColor")

            VStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        ImageListView(images: imageGenerator.generatedImages?.images)

                        Spacer()
                    }
                } // ScrollView
                .padding(.horizontal, 20)
            } // VStack
            .overlay {
                VStack {
                    HStack {
                        Button(action: { showingSettings = true }, label: {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                                .font(.title)
                        })
                        .padding(.top, 40)

                        Spacer()
                    }

                    Spacer()
                    StatusView(generating: !isGeneratorIdle,
                               progressStep: imageGenerator.progressStep)
                    Spacer()

                    HStack {
                        Button(action: saveImages) {
                            Image(systemName: "square.and.arrow.down.on.square")
                                .font(.title2)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isGeneratorIdle || !imageExists)

                        Spacer()

                        Button(action: showgenerationPanel, label: {
                            Text("Generate")
                                .font(.title2)
                        })
                        .buttonStyle(.borderedProminent)
                        .disabled(!isGeneratorIdle)

                        Spacer()

                        Button(action: displayAR, label: {
                            Image(systemName: "arkit")
                                .font(.title2)
                        })
                        .buttonStyle(.borderedProminent)
                        .disabled(ProcessInfo.processInfo.isiOSAppOnMac
                                  || !imageExists
                                  || !isGeneratorIdle)
                    }
                }
                .padding(24)
            }
            .fullScreenCover(isPresented: $showingAR) {
                if let images = imageGenerator.generatedImages?.images {
                    ARContentView(images: images,
                                  arDebugOptionOn: arDebugOptionOn,
                                  peopleOcclusionOn: peopleOcclusionOn,
                                  objectOcclusionOn: objectOcclusionOn,
                                  intervalTime: intervalTime)
                } else {
                    Text("no content")
                }
            }
            .sheet(isPresented: $showingGenPanel,
                   onDismiss: {
                if willGenerate {
                    willGenerate = false
                    generate()
                }
            }, content: {
                ParameterView(param: $genParameter,
                              willGenerate: $willGenerate)
                    .ignoresSafeArea()
                    .presentationDetents([.medium, .large])
            })
            .sheet(isPresented: $showingSettings,
                   onDismiss: {
            }, content: {
                SettingsView(
                    stableDiffusionOn: $stableDiffusionOn,
                    peopleOcclusionOn: $peopleOcclusionOn,
                    objectOcclusionOn: $objectOcclusionOn,
                    arDebugOptionOn: $arDebugOptionOn,
                    intervalTime: $intervalTime
                )
                    .ignoresSafeArea()
                    .presentationDetents([.medium, .large])
            })
        } // ZStack
        .ignoresSafeArea()
        .foregroundColor(.white)
    }

    private func showgenerationPanel() {
        showingGenPanel = true
    }

    private func saveImages() {
        guard let images = imageGenerator.generatedImages?.images else { return }
        imageGenerator.saveImagesIntoPhotoLibrary(images: images)
    }

    private func displayAR() {
        guard imageExists else { return }
        showingAR = true
    }

    private func generate() {
        // imageGenerator.removeSDPipeline()

        // Generate images
        let param = ImageGenerator.GenerationParameter(
                            prompt: genParameter.prompt,
                            seed: genParameter.randomSeed ? Int.random(in: 0...999)
                                                : Int(genParameter.seed),
                            stepCount: Int(genParameter.stepCount),
                            imageCount: genParameter.imageCount,
                            disableSafety: false)
        imageGenerator.generateImages(of: param,
            enableStableDiffusion: stableDiffusionOn)
    }
}

struct ImgGenView_Previews: PreviewProvider {
    static let imageGenerator = ImageGenerator()
    static var previews: some View {
        ImgGenView(imageGenerator: imageGenerator)
    }
}
