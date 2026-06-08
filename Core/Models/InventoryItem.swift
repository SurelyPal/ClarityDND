//
//  InventoryItem.swift
//  Clarity
//
//  Created by KEBAB on 04.06.2026.
//


import Foundation

struct InventoryItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var description: String = ""
    var stats: String = ""
    var isEquipped: Bool = false  // ✅ По умолчанию ВСЕГДА false
    var slot: EquipmentSlot = .none
    
    /// Проверяет валидность состояния: если предмет не экипируемый — не может быть надет
    mutating func validateEquipState() {
        if !slot.isEquippable {
            isEquipped = false
        }
    }
}
