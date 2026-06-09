//
//  DMInventorySection.swift
//  Clarity
//
//  Created by KEBAB on 09.06.2026.
//

import SwiftUI

struct DMInventorySection: View {
    let member: PartyMember
    
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
    }
}
