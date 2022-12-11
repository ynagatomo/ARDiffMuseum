//
//  AssetManager.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/11.
//

import RealityKit

final class AssetManager {
    static let share = AssetManager()

    var modelEntities: [String: ModelEntity] = [:]

    private init() { }

    func loadModelEntity(of name: String) -> ModelEntity? {
        if let modelEntity = modelEntities[name] {
            return modelEntity
        }

        if let modelEntity = try? ModelEntity.loadModel(named: name) {
            modelEntities[name] = modelEntity
            return modelEntity
        }

        fatalError("Failed to load a picture frame model (\(name)).")
    }
}
