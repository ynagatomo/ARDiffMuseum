//
//  SettingsView.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/11.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var stableDiffusionOn: Bool
    @Binding var peopleOcclusionOn: Bool
    @Binding var objectOcclusionOn: Bool
    @Binding var arDebugOptionOn: Bool
    @Binding var intervalTime: Double

    var body: some View {
        ZStack {
            Color.gray

            VStack {
                HStack {
                    Text("Settings")
                        .font(.title3)
                        .padding(.horizontal, 8)
                    Text(Bundle.main.appName
                         + " v" + Bundle.main.appVersion
                         + " (" + Bundle.main.buildNumber + ")")
                    .font(.caption)

                    Spacer()
                    Button(action: dismiss.callAsFunction, label: {
                        Text("Done")
                    })
                    .font(.title3)
                    .padding(.horizontal, 8)
                }.padding(.top, 16)

                List {
                    #if DEBUG
                    Section(content: {
                        Toggle("AR debug info", isOn: $arDebugOptionOn)
                    },
                    header: { Text("Debug")})
                    #endif

                    Section(content: {
                        Toggle("Stable Diffusion v"
                               + AppConstant.stableDiffusionVersion,
                               isOn: $stableDiffusionOn)
                    }, header: {
                        Text("Stable Diffusion")
                    }, footer: {
                        // swiftlint:disable line_length
                        Text("Turn on to generate images. It will take a few minutes for the initialization at the first image generation.")
                            .foregroundStyle(.secondary)
                    })

                    Section(content: {
                        HStack {
                            Text("Interval [sec]: \(Int(intervalTime), specifier: "%3d")")
                            Slider(value: $intervalTime,
                                   in: 1...60,
                                   step: 1,
                                   minimumValueLabel: Text("1"),
                                   maximumValueLabel: Text("60")) {
                                Text("Interval")
                            }
                        }
                        Toggle("People Occlusion", isOn: $peopleOcclusionOn)
                            .disabled(!ARViewController.peopleOcclusionSupported)
                        Toggle("Object Occlusion", isOn: $objectOcclusionOn)
                            .disabled(!ARViewController.objectOcclusionSupported)
                    },
                    header: { Text("AR Display")})
                }
                .foregroundColor(.primary)
                .tint(.orange)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    @State static var stableDiffusionOn = false
    @State static var peopleOcclusionOn = true
    @State static var objectOcclusionOn = true
    @State static var arDebugOptionOn = true
    @State static var intervalTime = 3.0

    static var previews: some View {
        SettingsView(stableDiffusionOn: $stableDiffusionOn,
                     peopleOcclusionOn: $peopleOcclusionOn,
                     objectOcclusionOn: $objectOcclusionOn,
                     arDebugOptionOn: $arDebugOptionOn,
                     intervalTime: $intervalTime)
    }
}
