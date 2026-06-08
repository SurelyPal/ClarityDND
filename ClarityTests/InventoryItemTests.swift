//
//  InventoryItemTests.swift
//  ClarityTests
//
//  Created by AI on 07.06.2026.
//
import XCTest
@testable import Clarity

final class InventoryItemTests: XCTestCase {
    
    // MARK: - Initial State
    
    func testNewItem_IsNotEquippedByDefault() {
        let item = InventoryItem()
        XCTAssertFalse(item.isEquipped, "Новый предмет не должен быть экипирован")
    }
    
    func testNewItem_HasEmptyFields() {
        let item = InventoryItem()
        XCTAssertTrue(item.name.isEmpty)
        XCTAssertTrue(item.description.isEmpty)
        XCTAssertTrue(item.stats.isEmpty)
    }
    
    func testNewItem_HasNoneSlot() {
        let item = InventoryItem()
        XCTAssertEqual(item.slot, .none)
    }
    
    // MARK: - validateEquipState
    
    func testValidateEquipState_EquippableSlot_KeepsState() {
        var item = InventoryItem()
        item.slot = .mainHand
        item.isEquipped = true
        
        item.validateEquipState()
        
        XCTAssertTrue(item.isEquipped,
                      "Предмет в экипируемом слоте должен остаться надетым")
    }
    
    func testValidateEquipState_NonEquippableSlot_ForcesUnequip() {
        var item = InventoryItem()
        item.slot = .consumable  // расходник нельзя надеть
        item.isEquipped = true   // но кто-то случайно поставил true
        
        item.validateEquipState()
        
        XCTAssertFalse(item.isEquipped,
                       "Предмет в не-экипируемом слоте должен быть снят")
    }
    
    func testValidateEquipState_PotionSlot_ForcesUnequip() {
        var item = InventoryItem()
        item.slot = .potion
        item.isEquipped = true
        
        item.validateEquipState()
        
        XCTAssertFalse(item.isEquipped, "Зелья нельзя экипировать")
    }
    
    // MARK: - EquipmentSlot.isEquippable
    
    func testEquipmentSlot_EquippableSlots() {
        let equippable: [EquipmentSlot] = [
            .mainHand, .offHand, .head, .chest,
            .hands, .legs, .feet, .ring1, .ring2, .amulet
        ]
        
        for slot in equippable {
            XCTAssertTrue(slot.isEquippable,
                          "Слот \(slot.rawValue) должен быть экипируемым")
        }
    }
    
    func testEquipmentSlot_NonEquippableSlots() {
        let nonEquippable: [EquipmentSlot] = [
            .none, .ammo, .potion, .consumable, .misc
        ]
        
        for slot in nonEquippable {
            XCTAssertFalse(slot.isEquippable,
                           "Слот \(slot.rawValue) не должен быть экипируемым")
        }
    }
    
    // MARK: - Identifiable & Hashable
    
    func testTwoItems_HaveDifferentIDs() {
        let item1 = InventoryItem()
        let item2 = InventoryItem()
        XCTAssertNotEqual(item1.id, item2.id)
    }
    
    func testItem_CanBeUsedInSet() {
        var item = InventoryItem()
        item.name = "Меч"
        
        var set: Set<InventoryItem> = []
        set.insert(item)
        
        XCTAssertEqual(set.count, 1)
    }
}
