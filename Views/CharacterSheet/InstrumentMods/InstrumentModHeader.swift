//
//  InstrumentModHeader.swift
//  Clarity
//
//  Created by KEBAB on 05.06.2026.
//
import SwiftUI

/// Тематический заголовок вкладки модификаций
/// Меняет цветовую схему и лор в зависимости от типа инструмента
struct InstrumentModHeader: View {
    @Environment(\.theme) private var theme
    let instrument: InstrumentType
    
    @State private var glowPulse: Double = 0.5
    
    var body: some View {
        VStack(spacing: 16) {
            // Иконка инструмента с тематическим свечением
            ZStack {
                // Пульсирующее свечение
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                instrument.glowColor,
                                instrument.accentColor.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 15)
                    .opacity(glowPulse)
                
                // SF Symbol инструмента
                Image(systemName: instrument.sfSymbol)
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(instrument.accentColor)
                    .shadow(color: instrument.accentColor.opacity(0.6), radius: 8)
            }
            
            VStack(spacing: 6) {
                Text("МОДИФИКАЦИИ")
                    .font(.system(size: 10))
                    .tracking(3)
                    .foregroundColor(theme.textDim)
                
                Text(instrument.rawValue.uppercased())
                    .font(.system(size: 26, weight: .light))
                    .tracking(3)
                    .foregroundColor(instrument.accentColor)
                
                Text(instrument.loreDescription)
                    .font(.system(size: 11, weight: .light))
                    .italic()
                    .foregroundColor(theme.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            DSdivider()
                .padding(.horizontal, 40)
        }
        .padding(.top, 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                glowPulse = 1.0
            }
        }
    }
}
