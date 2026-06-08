//
//  CharacterStoreTests.swift
//  ClarityTests
//
//  Created by KEBAB on 05.06.2026.
//
import XCTest
import SwiftData
@testable import Clarity

@MainActor
final class CharacterStoreTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var store: CharacterStore!
    
    override func setUp() async throws {
        // 🧪 In-memory контейнер: данные живут только в рамках одного теста
        // Каждый тест начинается с чистой базой
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: DNDCharacter.self, configurations: config)
        context = container.mainContext
        store = CharacterStore(context: context)
    }
    
    override func tearDown() {
        store = nil
        context = nil
        container = nil
    }
    
    // MARK: - CRUD
    
    func testAddCharacter_IncreasesCount() {
        let char = DNDCharacter()
        char.name = "Арагорн"
        
        store.add(char)
        
        XCTAssertEqual(store.characters.count, 1, "После добавления должен быть 1 персонаж")
        XCTAssertEqual(store.characters.first?.name, "Арагорн")
    }
    
    func testDeleteCharacter_DecreasesCount() {
        let char1 = DNDCharacter(); char1.name = "Первый"
        let char2 = DNDCharacter(); char2.name = "Второй"
        store.add(char1)
        store.add(char2)
        
        XCTAssertEqual(store.characters.count, 2)
        
        store.delete(at: IndexSet(integer: 0))
        
        XCTAssertEqual(store.characters.count, 1, "После удаления должен остаться 1 персонаж")
    }
    
    func testUpdateCharacter_PersistsChanges() {
        let char = DNDCharacter()
        char.name = "До обновления"
        store.add(char)
        
        char.name = "После обновления"
        store.update(char)
        
        XCTAssertEqual(store.characters.first?.name, "После обновления")
    }
    
    func testFetchAll_ReturnsSortedByName() {
        let b = DNDCharacter(); b.name = "Бета"
        let a = DNDCharacter(); a.name = "Альфа"
        let c = DNDCharacter(); c.name = "Вектор"
        store.add(b)
        store.add(a)
        store.add(c)
        
        XCTAssertEqual(store.characters[0].name, "Альфа")
        XCTAssertEqual(store.characters[1].name, "Бета")
        XCTAssertEqual(store.characters[2].name, "Вектор")
    }
    
    // MARK: - Краевые случаи
    
    func testEmptyStore_HasNoCharacters() {
        XCTAssertTrue(store.characters.isEmpty)
    }
    
    func testDeleteFromEmptyStore_DoesNotCrash() {
        // Не должно упасть даже при удалении из пустого списка
        store.delete(at: IndexSet())
        XCTAssertEqual(store.characters.count, 0)
    }
    
    func testMultipleSaves_DoNotDuplicate() {
        let char = DNDCharacter()
        char.name = "Тест"
        store.add(char)
        store.update(char)
        store.update(char)
        
        XCTAssertEqual(store.characters.count, 1, "Несколько update не должны дублировать персонажа")
    }
}
