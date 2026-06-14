//
//  PointBuyRow.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct PointBuyRow: View {
    @Environment(\.theme) private var theme
    let label: String
    @Binding var value: Int
    let pointsLeft: Int
    
    private var modifier: Int {
        Constants.Stat.modifier(for: value)
    }
    
    private var modText: String {
        Constants.Stat.formattedModifier(modifier)
    }
    
    private var increasePrice: Int {
        Constants.Stat.costToIncrease(from: value)
    }
    
    private var canIncrease: Bool {
        value < Constants.Stat.maxValue && pointsLeft >= increasePrice
    }
    
    private var canDecrease: Bool {
        value > Constants.Stat.minValue
    }
    
    private var valueColor: Color {
        if value >= 14 { return theme.primary }
        if value >= 10 { return theme.text }
        return theme.textDim
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(theme.text)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            priceLabel
            decreaseButton
            valueDisplay
            increaseButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(
            Rectangle()
                .fill(theme.border)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    private var priceLabel: some View {
        Group {
            if value < Constants.Stat.maxValue {
                Text("+\(increasePrice)★")
                    .foregroundColor(canIncrease ? theme.textDim : theme.danger.opacity(0.6))
            } else {
                Text("макс")
                    .foregroundColor(theme.primaryDim)
            }
        }
        .font(.system(size: 10))
        .frame(width: 34)
    }
    
    private var decreaseButton: some View {
        Button {
            guard canDecrease else { return }
            withAnimation(.spring(response: 0.2)) { value -= 1 }
        } label: {
            Image(systemName: "minus")
                .frame(width: 30, height: 30)
                .background(canDecrease ? theme.surfaceAlt : theme.surface)
                .foregroundColor(canDecrease ? theme.text : theme.textDim)
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(theme.border, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var valueDisplay: some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(valueColor)
            Text(modText)
                .font(.system(size: 10))
                .foregroundColor(theme.textDim)
        }
        .frame(width: 36)
        .animation(.spring(response: 0.2), value: value)
    }
    
    private var increaseButton: some View {
        Button {
            guard canIncrease else { return }
            withAnimation(.spring(response: 0.2)) { value += 1 }
        } label: {
            Image(systemName: "plus")
                .frame(width: 30, height: 30)
                .background(canIncrease ? theme.surfaceAlt : theme.surface)
                .foregroundColor(canIncrease ? theme.primary : theme.textDim)
                .cornerRadius(2)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(theme.border, lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}
