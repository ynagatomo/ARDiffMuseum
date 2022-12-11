//
//  ARViewController.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/06.
//

import UIKit
import ARKit
import RealityKit
import Combine

// swiftlint:disable file_length

final class ARViewController: UIViewController {
    private var arView: ARView!
    private var anchorEntity: AnchorEntity?
    private var planeTranslation: SIMD3<Float> = .zero
    private var pictureFrameModelEntity: ModelEntity?
    private var pictureFrameTextures: [PhysicallyBasedMaterial.Texture] = []
    private var displayingTextureIndex = 0
    private var arSessionConfig: ARWorldTrackingConfiguration!

    private var renderLoopSubscription: Cancellable?
    private var cumulativeTimeForTexture: Double = 0
    private var cumulativeTimeForScale: Double = 0

    private var pictureFrameIndex = 0
    private var arDebugOptionOn = false
    private var peopleOcclusionOn = false
    private var objectOcclusionOn = false
    private var intervalTime: Double = 0

    static var peopleOcclusionSupported: Bool {
        ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth)
    }
    static var objectOcclusionSupported: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        #if !targetEnvironment(simulator)
        // running on a real device
        arView = ARView(frame: .zero,
                        cameraMode: .ar,
                        automaticallyConfigureSession: true)
        #else
        // running on a simulator
        arView = ARView(frame: .zero)
        #endif
        view = arView

        #if DEBUG
        if arDebugOptionOn {
            arView.debugOptions = [ // .showAnchorOrigins,
                // .showPhysics : collision shapes
                .showStatistics,
                .showWorldOrigin
                // .showAnchorGeometry,
                // .showFeaturePoints
            ]
        }
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.session.delegate = self
        startPlaneDetectionARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
        arView.session.pause()
    }
}

// MARK: - Setup

extension ARViewController {
    func setImages(_ images: [UIImage]) {
        images.forEach {
            if let cgImage = $0.cgImage {
                let options = TextureResource.CreateOptions(semantic: .color)
                if let textureRes = try? TextureResource.generate(from: cgImage,
                                                                  options: options) {
                    let texture = PhysicallyBasedMaterial.Texture(textureRes)
                    pictureFrameTextures.append(texture)
                }
            }
        }
    }

    func setOptions(arDebugOptionOn: Bool, peopleOcclusionOn: Bool, objectOcclusionOn: Bool, intervalTime: Double) {
        self.arDebugOptionOn = arDebugOptionOn
        self.peopleOcclusionOn = peopleOcclusionOn
        self.objectOcclusionOn = objectOcclusionOn
        self.intervalTime = intervalTime
    }
}

// MARK: - Render Loop

extension ARViewController {
    private func stopSession() {
        renderLoopSubscription = nil
    }

    private func startSession() {
        renderLoopSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { event in
            DispatchQueue.main.async {
                self.updateScene(deltaTime: event.deltaTime)
            }
        }
    }

    private func updateScene(deltaTime: Double) {
        cumulativeTimeForTexture += deltaTime
        cumulativeTimeForScale += deltaTime

        // change the scale

        if cumulativeTimeForScale > AppConstant.scaleChangeIntervalTime {
            cumulativeTimeForScale = 0
            let diff = arView.cameraTransform.translation - planeTranslation
            let distance = sqrtf(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z)
            //        debugLog("DEBUG: distance = \(squareDistance)")
            if distance > 3.0 {
                let scale = distance - 3 + 1
                pictureFrameModelEntity?.scale = SIMD3<Float>(repeating: scale)
            }
        }

        // change the texture

        guard pictureFrameTextures.count >= 2 else { return }

        if cumulativeTimeForTexture > intervalTime {
            cumulativeTimeForTexture = 0
            displayingTextureIndex = displayingTextureIndex >= (pictureFrameTextures.count - 1)
                                    ? 0 : (displayingTextureIndex + 1)
            var material = UnlitMaterial()
            material.color.texture = pictureFrameTextures[displayingTextureIndex]
            pictureFrameModelEntity?.model?.materials[0] = material
        }
    }
}

// MARK: - Update

extension ARViewController {
    func update(pictureFrameIndex: Int) {
        assert(pictureFrameIndex >= 0
               && pictureFrameIndex < AppConstant.pictureFrameSpecs.count)

        self.pictureFrameIndex = pictureFrameIndex
        pictureFrameModelEntity = loadPictureFrameModel(of: pictureFrameIndex)
    }

    private func loadPictureFrameModel(of frameIndex: Int) -> ModelEntity? {
        assert(pictureFrameIndex >= 0
               && pictureFrameIndex < AppConstant.pictureFrameSpecs.count)

        return AssetManager.share.loadModelEntity(of:
                                       AppConstant.pictureFrameSpecs[frameIndex].modelName)
    }

    private func addPictureEntity() {
        guard let anchorEntity else { return }

        //    let meshRes = MeshResource.generateBox(size: 0.5)
        //    let material = SimpleMaterial(color: .red, isMetallic: false)
        //    let model = ModelEntity(mesh: meshRes, materials: [material])
        //    anchorEntity.addChild(model)

        if let pictureFrameModelEntity {
            if !pictureFrameTextures.isEmpty {
                var material = UnlitMaterial()
                material.color.texture = pictureFrameTextures[displayingTextureIndex]
                pictureFrameModelEntity.model?.materials[0] = material
            }

            pictureFrameModelEntity.scale = SIMD3<Float>(1, 1, 1)
            anchorEntity.addChild(pictureFrameModelEntity)
            pictureFrameModelEntity.orientation = simd_quatf(angle: Float.pi / 2,
                                                             axis: SIMD3<Float>(1, 0, 0))
            * simd_quatf(angle: Float.pi, axis: SIMD3<Float>(0, 1, 0))
            * simd_quatf(angle: Float.pi, axis: SIMD3<Float>(0, 0, 1))
        }
    }
}

// MARK: - ARSession

extension ARViewController {
    private func startPlaneDetectionARSession() {
        assert(arSessionConfig == nil)
        #if !targetEnvironment(simulator)
        // running on an real devices
        arSessionConfig = ARWorldTrackingConfiguration()
        arSessionConfig.planeDetection = [.vertical]

        if peopleOcclusionOn {
            if Self.peopleOcclusionSupported {
                arSessionConfig.frameSemantics.insert(.personSegmentationWithDepth)
                debugLog("AR: People Occlusion was enabled.")
            } else {
                debugLog("AR: This device does not support People Occlusion.")
            }
        }

        // [Note]
        // When you enable scene reconstruction, ARKit provides a polygonal mesh
        // that estimates the shape of the physical environment.
        // If you enable plane detection, ARKit applies that information to the mesh.
        // Where the LiDAR scanner may produce a slightly uneven mesh on a real-world surface,
        // ARKit smooths out the mesh where it detects a plane on that surface.
        // If you enable people occlusion, ARKit adjusts the mesh according to any people
        // it detects in the camera feed. ARKit removes any part of the scene mesh that
        // overlaps with people
        if objectOcclusionOn {
            if Self.objectOcclusionSupported {
                arSessionConfig.sceneReconstruction = .mesh
                arView.environment.sceneUnderstanding.options.insert(.occlusion)
                debugLog("AR: Object Occlusion was enabled.")
            } else {
                debugLog("AR: This device does not support Object Occlusion.")
            }
        }

        arView.session.run(arSessionConfig)
        #else
        // running on a simulator => do nothing
        #endif
    }

    private func startNonPlaneDetectionARSession() {
        assert(arSessionConfig != nil)
        #if !targetEnvironment(simulator)
        // running on an real devices
        arSessionConfig.planeDetection = []
        arView.session.run(arSessionConfig, options: [])
        #else
        // running on a simulator => do nothing
        #endif
    }
}

// MARK: - ARSessionDelegate

extension ARViewController: ARSessionDelegate {
    #if !targetEnvironment(simulator)
    /// tells that ARAnchors was added cause of like a plane-detection
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // debugLog("AR: AR-DELEGATE: didAdd anchors: [ARAnchor] : \(anchors)")
        // <AREnvironmentProbeAnchor> can be added for environmentTexturing

        // [@Log] : ARViewController.swift: session(_:didAdd:): L75: T(m): AR: AR-DELEGATE:
        // didAdd anchors: [ARAnchor] : [<ARPlaneAnchor: 0x11518ec90 identifier="0B761030-6B6D-4728-82EE-C9832FFAD03A"
        // transform=<translation=(0.098125 -0.109026 -0.752609) rotation=(90.00° 0.00° -25.73°)>
        // alignment=vertical center=(-0.075000 0.000000 0.075000) extent=(0.750000 0.000000 0.950000)
        // classification=Wall>]

        for anchor in anchors {
            if let arPlaneAnchor = anchor as? ARPlaneAnchor {
                // debugLog("AR: AR-DELEGATE: didAdd an ARPlaneAnchor : \(arPlaneAnchor)")
                planeTranslation = SIMD3<Float>(arPlaneAnchor.transform[3].x,
                                    arPlaneAnchor.transform[3].y,
                                    arPlaneAnchor.transform[3].z)
                anchorEntity = AnchorEntity(anchor: arPlaneAnchor)

                arView.scene.addAnchor(anchorEntity!)
                addPictureEntity()
                startNonPlaneDetectionARSession()
                startSession()
                break
            }
        }
    }
    #endif

    //    /// tells that ARAnchors were changed cause of like a progress of plane-detection
    //    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    //        debugLog("AR: AR-DELEGATE: ARSessionDelegate: session(_:didUpdate) was called. \(anchors) were updated.")
    //        // <AREnvironmentProbeAnchor> can be added for environmentTexturing
    //
    //        // [@Log] : ARViewController.swift: session(_:didUpdate:): L81: T(m): AR: AR-DELEGATE:
    //        // ARSessionDelegate: session(_:didUpdate) was called. [<ARPlaneAnchor: 0x11506b370
    //        // identifier="EA9D93EC-29E9-432B-9260-5717E592D56B" transform=<translation=(0.525457 1.035591 -0.706190)
    //        // rotation=(89.79° 116.35° -179.72°)> alignment=vertical center=(0.150000 0.000000 -0.050000)
    //        // extent=(0.700000 0.000000 0.400000) classification=Wall>
    //    }

    //    /// tells that the ARAnchors were removed
    //    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    //        // debugLog("AR: AR-DELEGATE: The session(_:didRemove) was called.  [ARAnchor] were removed.")
    //        assertionFailure("The session(_:didUpdate) should not be called.")
    //    }

    //    /// tells that the AR session was interrupted due to app switching or something
    //    func sessionWasInterrupted(_ session: ARSession) {
    //        debugLog("AR: AR-DELEGATE: The sessionWasInterrupted(_:) was called.")
    //        // Nothing to do. The system handles all.
    //
    //        // DispatchQueue.main.async {
    //        //   - do something if necessary
    //        // }
    //    }

    //    /// tells that the interruption was ended
    //    func sessionInterruptionEnded(_ session: ARSession) {
    //        debugLog("AR: AR-DELEGATE: The sessionInterruptionEnded(_:) was called.")
    //        // Nothing to do. The system handles all.
    //
    //        // DispatchQueue.main.async {
    //        //   - reset the AR tracking
    //        //   - do something if necessary
    //        // }
    //    }

    //    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
    // swiftlint:disable line_length
    //        debugLog("AR: AR-DELEGATE: The session(_:cameraDidChangeTrackingState:) was called. cameraState = \(camera.trackingState)")
    //    }

    //    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    //        // You can get the camera's (device's) position in the virtual space
    //        // from the transform property.
    //        // The 4th column represents the position, (x, y, z, -).
    //        let cameraTransform = frame.camera.transform
    //        // The orientation of the camera, expressed as roll, pitch, and yaw values.
    //        let cameraEulerAngles = frame.camera.eulerAngles // simd_float3
    //    }

    // tells that an error was occurred
    //
    // - When the users don't allow to access the camera, this delegate will be called.
    // swiftlint:disable cyclomatic_complexity
    func session(_ session: ARSession, didFailWithError error: Error) {
        debugLog("AR: AR-DELEGATE: The didFailWithError was called.")
        debugLog("AR: AR-DELEGATE:     error = \(error.localizedDescription)")
        guard let arerror = error as? ARError else { return }

        #if DEBUG
        // print the errorCase
        let errorCase: String
        switch arerror.errorCode {
        case ARError.Code.requestFailed.rawValue: errorCase = "requestFailed"
        case ARError.Code.cameraUnauthorized.rawValue: errorCase = "cameraUnauthorized"
        case ARError.Code.fileIOFailed.rawValue: errorCase = "fileIOFailed"
        case ARError.Code.insufficientFeatures.rawValue: errorCase = "insufficientFeatures"
        case ARError.Code.invalidConfiguration.rawValue: errorCase = "invalidConfiguration"
        case ARError.Code.invalidReferenceImage.rawValue: errorCase = "invalidReferenceImage"
        case ARError.Code.invalidReferenceObject.rawValue: errorCase = "invalidReferenceObject"
        case ARError.Code.invalidWorldMap.rawValue: errorCase = "invalidWorldMap"
        case ARError.Code.microphoneUnauthorized.rawValue: errorCase = "microphoneUnauthorized"
        case ARError.Code.objectMergeFailed.rawValue: errorCase = "objectMergeFailed"
        case ARError.Code.sensorFailed.rawValue: errorCase = "sensorFailed"
        case ARError.Code.sensorUnavailable.rawValue: errorCase = "sensorUnavailable"
        case ARError.Code.unsupportedConfiguration.rawValue: errorCase = "unsupportedConfiguration"
        case ARError.Code.worldTrackingFailed.rawValue: errorCase = "worldTrackingFailed"
        case ARError.Code.geoTrackingFailed.rawValue: errorCase = "geoTrackingFailed"
        case ARError.Code.geoTrackingNotAvailableAtLocation.rawValue: errorCase = "geoTrackingNotAvailableAtLocation"
        case ARError.Code.locationUnauthorized.rawValue: errorCase = "locationUnauthorized"
        case ARError.Code.invalidCollaborationData.rawValue: errorCase = "invalidCollaborationData"
        default: errorCase = "unknown"
        }
        debugLog("AR: AR-DELEGATE:     errorCase = \(errorCase)")

        // print the errorWithInfo
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        // remove optional error messages and connect into one string
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        debugLog("AR: AR-DELEGATE:     errorWithInfo: \(errorMessage)")
        #endif

        // handle the issues
        if arerror.errorCode == ARError.Code.cameraUnauthorized.rawValue {
            // Error: The camera access is not allowed.
            debugLog("AR: AR-DELEGATE:     The camera access is not authorized.")

            // Show the alert message.
            // "The use of the camera is not permitted.\nPlease allow it with the Settings app."
        } else if arerror.errorCode == ARError.Code.unsupportedConfiguration.rawValue {
            // Error: Unsupported Configuration
            // It means that now the AR session is trying to run on macOS(w/M1) or Simulator.
            debugLog("AR: AR-DELEGATE:     unsupportedConfiguration. (running on macOS or Simulator)")
            assertionFailure("invalid ARSession on macOS or Simulator.")
            // Nothing to do in release mode.
        } else {
            // Error: Something else
            // Nothing to do.
        }
    }
}
