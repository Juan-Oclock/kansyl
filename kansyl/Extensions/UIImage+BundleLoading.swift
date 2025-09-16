//
//  UIImage+BundleLoading.swift
//  kansyl
//
//  Helper extension to load images from bundle resources
//

import UIKit
import SwiftUI

extension UIImage {
    /// Loads an image from bundle resources, trying multiple strategies
    static func bundleImage(named name: String) -> UIImage? {
        // Strategy 0: Check if this is a custom uploaded image (from Documents directory)
        if name.contains("_logo_") && (name.hasSuffix(".jpg") || name.hasSuffix(".png")) {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(name)
            if let image = UIImage(contentsOfFile: fileURL.path) {
                return image
            }
        }
        
        // Strategy 1: Try direct name (for images in Assets.xcassets)
        if let image = UIImage(named: name) {
            return image
        }
        
        // Strategy 1.5: Try with "-logo" suffix (common pattern in assets)
        if let image = UIImage(named: "\(name)-logo") {
            return image
        }
        
        // Strategy 2: Try with .png extension
        if let image = UIImage(named: "\(name).png") {
            return image
        }
        
        // Strategy 2.5: Try with "-logo.png" combination
        if let image = UIImage(named: "\(name)-logo.png") {
            return image
        }
        
        // Strategy 3: Try loading from bundle path directly
        let bundle = Bundle.main
        
        // Try without extension
        if let path = bundle.path(forResource: name, ofType: nil),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        // Try with png extension
        if let path = bundle.path(forResource: name, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        // Try with logo suffix and png extension
        if let path = bundle.path(forResource: "\(name)-logo", ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        
        // Strategy 4: Try in subdirectories (like docs/logos)
        let possiblePaths = [
            "logos/\(name)",
            "logos/\(name).png",
            "logos/\(name)-logo",
            "logos/\(name)-logo.png",
            "docs/logos/\(name)",
            "docs/logos/\(name).png",
            "docs/logos/\(name)-logo",
            "docs/logos/\(name)-logo.png"
        ]
        
        for possiblePath in possiblePaths {
            if let url = bundle.url(forResource: possiblePath, withExtension: nil),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }
        
        return nil
    }
}

extension Image {
    /// Creates a SwiftUI Image from a bundle resource with fallback
    static func bundleImage(_ name: String, fallbackSystemName: String = "questionmark.circle.fill") -> Image {
        if let uiImage = UIImage.bundleImage(named: name) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: fallbackSystemName)
        }
    }
}