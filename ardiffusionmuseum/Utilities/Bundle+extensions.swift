//
//  Bundle+extensions.swift
//  ardiffusionmuseum
//
//  Created by Yasuhito Nagatomo on 2022/12/08.
//

import Foundation

extension Bundle {
    var appName: String {
        return (object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? ""
    }

    var appVersion: String {
        return (object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? ""
    }

    var buildNumber: String {
        return (object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "0"
    }

    var buildNumberValue: Int {
        return Int((object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "0") ?? 0
    }
}
