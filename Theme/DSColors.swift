//
//  DSColors.swift
//  Clarity
//

import SwiftUI

// MARK: - Цветовая палитра
extension Color {
    static let dsBackground   = Color(red: 0.05, green: 0.07, blue: 0.12)
    static let dsSurface      = Color(red: 0.08, green: 0.11, blue: 0.18)
    static let dsSurfaceAlt   = Color(red: 0.11, green: 0.15, blue: 0.24)
    
    static let dsGold         = Color(red: 0.85, green: 0.68, blue: 0.28)
    static let dsGoldDim      = Color(red: 0.55, green: 0.43, blue: 0.15)
    
    static let dsRed          = Color(red: 0.75, green: 0.18, blue: 0.18)
    static let dsRedDim       = Color(red: 0.75, green: 0.18, blue: 0.18).opacity(0.25)
    
    static let dsBlue         = Color(red: 0.20, green: 0.35, blue: 0.65)
    
    static let dsBorder       = Color(red: 0.85, green: 0.68, blue: 0.28).opacity(0.25)
    static let dsBorderBright = Color(red: 0.85, green: 0.68, blue: 0.28).opacity(0.6)
    
    static let dsText         = Color(red: 0.88, green: 0.82, blue: 0.68)
    static let dsTextDim      = Color(red: 0.55, green: 0.50, blue: 0.40)
}
