//
//  StatusView.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/11.
//

import SwiftUI

struct StatusView: View {
    let generating: Bool
    let progressStep: (step: Int, stepCount: Int)

    var body: some View {
        VStack {
            if generating {
                if progressStep.step == 0 {
                    Text("Initializing... Wait for a few minutes.")
                        .padding()
                        .background(Color.black.opacity(0.5).cornerRadius(8))
                } else {
                    Text("Progress: \(progressStep.step) step / \(progressStep.stepCount) steps")
                        .padding()
                        .background(Color.black.opacity(0.5).cornerRadius(8))
                }
            } else {
                Color.clear
            }
        } // VStack
    }
}

struct StatusView_Previews: PreviewProvider {
    static var previews: some View {
        StatusView(generating: true, progressStep: (10, 20))
            .foregroundColor(.white)
    }
}
