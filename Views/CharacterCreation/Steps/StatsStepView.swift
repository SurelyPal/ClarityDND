//
//  StatsStepView.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//

import SwiftUI

struct StatsStepView: View {
    @Environment(\.theme) private var theme
    @Binding var stats: AbilityScores
    
    private var pointsSpent: Int {
        statCost(stats.strength) +
        statCost(stats.dexterity) +
        statCost(stats.constitution) +
        statCost(stats.intelligence) +
        statCost(stats.wisdom) +
        statCost(stats.charisma)
    }
    /// Если значение вне диапазона 8-15 — возвращает 0 вместо краша.
    private func statCost(_ value: Int) -> Int {
        Constants.Stat.pointBuyCost[value] ?? 0
    }
    private var pointsLeft: Int {
        Constants.Stat.pointBuyTotal - pointsSpent
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                stepHeader
                
                DSdivider().padding(.vertical, 8)
                
                pointsHeader
                hintText
                
                VStack(spacing: 0) {
                    PointBuyRow(label: "Сила",         value: $stats.strength,     pointsLeft: pointsLeft)
                    PointBuyRow(label: "Ловкость",     value: $stats.dexterity,    pointsLeft: pointsLeft)
                    PointBuyRow(label: "Телосложение", value: $stats.constitution, pointsLeft: pointsLeft)
                    PointBuyRow(label: "Интеллект",    value: $stats.intelligence, pointsLeft: pointsLeft)
                    PointBuyRow(label: "Мудрость",     value: $stats.wisdom,       pointsLeft: pointsLeft)
                    PointBuyRow(label: "Харизма",      value: $stats.charisma,     pointsLeft: pointsLeft)
                }
                .dsCard()
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Шаг 3 из 4")
                .font(.system(size: 11))
                .tracking(2)
                .foregroundColor(theme.textDim)
            Text("Характеристики")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(theme.primary)
        }
    }
    
    private var pointsHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.caption)
                .foregroundColor(pointsLeft == 0 ? theme.primaryDim : theme.primary)
            Text("Осталось очков: \(pointsLeft)")
                .font(.system(size: 14))
                .foregroundColor(pointsLeft == 0 ? theme.primaryDim : theme.primary)
            Spacer()
            Button("Сбросить") {
                withAnimation(.spring(response: 0.3)) {
                    stats.reset()
                }
            }
            .font(.system(size: 12))
            .foregroundColor(theme.textDim)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.surface)
        .cornerRadius(3)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(theme.border, lineWidth: 0.5)
        )
        .padding(.top, 4)
    }
    
    private var hintText: some View {
        Text("14→15 стоит 2 очка · максимум \(Constants.Stat.maxValue) · минимум \(Constants.Stat.minValue)")
            .font(.system(size: 10))
            .tracking(0.5)
            .foregroundColor(theme.textDim)
            .padding(.top, 4)
            .padding(.bottom, 4)
    }
}
