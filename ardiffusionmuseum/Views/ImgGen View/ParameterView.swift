//
//  ParameterView.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/11.
//

import SwiftUI

struct ParameterView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var param: ImgGenView.GenParameter
    @Binding var willGenerate: Bool
    @State private var selectedPrompt = 0

    var body: some View {
        ZStack {
            Color.gray
            VStack {
                Text("Generation Parameters").font(.title3)

                Stepper(value: $param.imageCount, in: 1...10) {
                    Text("Image Count: \(param.imageCount, specifier: "%3d")")
                }

                HStack {
                    Text("Guidance scale: \(param.guidanceScale, specifier: "%.1f")")

                    Slider(value: $param.guidanceScale,
                           in: 0.0...50.0,
                           step: 0.5,
                           minimumValueLabel: Text("0"),
                           maximumValueLabel: Text("50")) {
                        Text("label")
                    }
                }

                HStack {
                    Text("Steps: \(Int(param.stepCount), specifier: "%4d")")

                    Slider(value: $param.stepCount,
                           in: 1...99,
                           step: 1,
                           minimumValueLabel: Text("1"),
                           maximumValueLabel: Text("99")) {
                        Text("steps")
                    }
                }

                Toggle("Random seed", isOn: $param.randomSeed)

                if !param.randomSeed {
                    VStack {
//                        Text("Seed: \(Int(param.seed), specifier: "%10d")")
                        Text("Seed: \(param.seed, specifier: "%.0f")")
                        TextField("Seed", value: $param.seed,
                                  formatter: NumberFormatter())
                        .onSubmit {
                            if param.seed < 0 {
                                param.seed = 0
                            } else if param.seed > Double(UInt32.max) {
                                param.seed = Double(UInt32.max)
                            } else {
                                // do nothing
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.indigo)

                        Slider(value: $param.seed,
                               in: 0...4_294_967_295,
                               step: 1,
                               minimumValueLabel: Text("0"),
                               maximumValueLabel: Text("4B")
                        ) {
                            Text("seed")
                        }
                    }
                }

                Group {
                    Divider()
                    Text("Prompt")
                    TextField("Prompt", text: $param.prompt)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.indigo)
                        .padding(.vertical, 8)

                    Text("Registered Prompts")
                    Picker("Prompt", selection: $selectedPrompt) {
                        ForEach(0 ..< AppConstant.registeredPrompts.count,
                                id: \.self) {
                            Text(AppConstant.registeredPrompts[$0]).lineLimit(1)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedPrompt) { newValue in
                        param.prompt = AppConstant.registeredPrompts[newValue]
                    }
                }

                Group {
                    Divider()
                    Text("Negative Prompt")
                    TextField("Negative Prompt", text: $param.negativePrompt)
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.indigo)
                        .padding(.vertical, 8)
                }

                HStack {
                    Button(action: dismiss.callAsFunction) {
                        Text("Close").font(.title2)
                    }
                    .buttonStyle(.bordered)
                    .padding(8)

                    Button(action: {
                        willGenerate = true
                        dismiss()
                    }, label: {
                        Text("Generate")
                            .font(.title2)
                    })
                    .buttonStyle(.bordered)
                    .padding(8)
                }

                Spacer()
            } // VStack
            .tint(.orange)
            .padding(8)
        } // ZStack
    }
}

struct ParameterView_Previews: PreviewProvider {
    @State static var param = ImgGenView.GenParameter(prompt: "",
                                                      imageCount: 1,
                                                      stepCount: 20,
                                                      seed: 100,
                                                      randomSeed: false)
    @State static var willGenerate = false

    static var previews: some View {
        ParameterView(param: $param, willGenerate: $willGenerate)
            .foregroundColor(.white)
    }
}
