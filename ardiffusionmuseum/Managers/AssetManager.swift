//
//  AssetManager.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/11.
//

import RealityKit

final class AssetManager {
    static let share = AssetManager()
    //    var modelEntities: [String: ModelEntity] = [:]
    var modelEntity: ModelEntity?

    private init() { }

    func loadModelEntity(of name: String) -> ModelEntity? {
        // TODO: Remove this workaround code.
        //       This is to deal with an internal error in MPS due to the combination of
        //       RealityKit APIs such as ModelEntity.load(named:) and CoreML Stable Diffusion.
        if modelEntity == nil {
            let meshRes = MeshResource.generatePlane(width: 0.5, height: 0.5)
            let material = SimpleMaterial(color: .gray, isMetallic: false)
            modelEntity = ModelEntity(mesh: meshRes, materials: [material])
        }

        return modelEntity

        // Original code -----------------------------------------------------
        //        if let modelEntity = modelEntities[name] {
        //            return modelEntity
        //        }
        //
        //        if let modelEntity = try? ModelEntity.loadModel(named: name) {
        //            modelEntities[name] = modelEntity
        //            return modelEntity
        //        }
        //
        //        fatalError("Failed to load a picture frame model (\(name)).")
    }
}
