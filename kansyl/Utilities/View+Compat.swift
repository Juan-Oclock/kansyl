//
//  View+Compat.swift
//  kansyl
//
//  Conditional helpers for APIs available only on newer iOS versions
//

import SwiftUI

extension View {
    @ViewBuilder
    func halfHeightDetent() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.fraction(0.5)])
        } else {
            self
        }
    }
    
    @ViewBuilder
    func expandableHeightDetent() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.fraction(0.5), .large])
        } else {
            self
        }
    }
    
    @ViewBuilder
    func fullHeightDetent() -> some View {
        if #available(iOS 16.0, *) {
            self.presentationDetents([.large])
        } else {
            self
        }
    }
}
