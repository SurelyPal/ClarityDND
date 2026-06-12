//
// DMInventorySection.swift
// Clarity
//
// Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct DMInventorySection: View {
    let member: PartyMember
    @ObservedObject var partyManager: PartyManager
    
    @State private var showingMoneyDialog = false
    @State private var moneyAmount = ""
    @State private var moneyReason = ""
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("ИНВЕНТАРЬ")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundColor(Color.dsTextDim)
                Spacer()
                if let inv = member.inventory {
                    Text("\(inv.count) предм.")
                        .font(.system(size: 10))
                        .foregroundColor(Color.dsTextDim)
                }
            }
            .padding(.horizontal, 16)
            
            // ✅ НОВОЕ: Секция денег (ВСЕГДА видна, даже если money == nil)
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(Color.dsGold)
                Text("Золото: \(member.money ?? 0)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.dsGold)
                
                Spacer()
                
                Button {
                    showingMoneyDialog = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Изменить")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(Color.dsGold)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.dsGold.opacity(0.1))
            .cornerRadius(6)
            .padding(.horizontal, 16)
            
            if let inventory = member.inventory, !inventory.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(inventory.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 10) {
                            Image(systemName: IconHelper.iconForItem(item))
                                .font(.system(size: 14))
                                .foregroundColor(Color.dsGoldDim)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.dsText)
                                
                                if !item.description.isEmpty {
                                    Text(item.description)
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.dsTextDim)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                            
                            if item.isEquipped {
                                Text("Экип.")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Color.dsGold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.dsGold.opacity(0.15))
                                    .cornerRadius(3)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if index < inventory.count - 1 {
                                Rectangle()
                                    .fill(Color.dsBorder)
                                    .frame(height: 0.5)
                            }
                        }
                    }
                }
                .dsCard()
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "bag")
                        .font(.system(size: 32))
                        .foregroundColor(Color.dsTextDim.opacity(0.4))
                    Text("Инвентарь пуст")
                        .font(.system(size: 12))
                        .foregroundColor(Color.dsTextDim)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .dsCard()
                .padding(.horizontal, 16)
            }
        }
        .sheet(isPresented: $showingMoneyDialog) {
            VStack(spacing: 16) {
                Text("✦ ИЗМЕНИТЬ ЗОЛОТО ✦")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color.dsGold)
                
                Text("Текущий запас: \(member.money ?? 0) монет")
                    .font(.system(size: 13))
                    .foregroundColor(Color.dsTextDim)
                
                DSdivider()
                    .padding(.horizontal, 40)
                
                VStack(spacing: 12) {
                    TextField("Сумма (например, 50 или -20)", text: $moneyAmount)
                    #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                    #endif
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Причина (опционально)", text: $moneyReason)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 20)
                
                HStack(spacing: 12) {
                    Button {
                        showingMoneyDialog = false
                        moneyAmount = ""
                        moneyReason = ""
                    } label: {
                        Text("ОТМЕНА")
                            .font(.system(size: 12, weight: .medium))
                            .tracking(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.dsSurfaceAlt)
                            .foregroundColor(Color.dsText)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        if let amount = Int(moneyAmount) {
                            let newAmount = (member.money ?? 0) + amount
                            partyManager.sendMoneyUpdate(
                                to: member.peerID,
                                characterID: member.id,
                                amount: newAmount,
                                reason: moneyReason.isEmpty ? "Изменение ДМом" : moneyReason
                            )
                        }
                        showingMoneyDialog = false
                        moneyAmount = ""
                        moneyReason = ""
                    } label: {
                        Text("ПРИМЕНИТЬ")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.dsGold)
                            .foregroundColor(Color.dsBackground)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
            .background(Color.dsBackground)
            .presentationDetents([.height(320)])
        }
    }
}
