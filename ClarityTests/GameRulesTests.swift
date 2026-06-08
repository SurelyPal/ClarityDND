//
//  GameRulesTests.swift
//  Clarity
//
//  Created by KEBAB on 07.06.2026.
//


//
//  GameRulesTests.swift
//  ClarityTests
//
//  Created by AI on 07.06.2026.
//
import XCTest
@testable import Clarity

final class GameRulesTests: XCTestCase {
    
    // MARK: - Default Values
    
    func testDefault_AllowsEditingOutsideParty() {
        let rules = GameRules.default
        XCTAssertTrue(rules.canEditCharacterOutsideParty,
                      "По умолчанию редактирование вне партии разрешено")
    }
    
    func testDefault_Init_HasSameValues() {
        let rules1 = GameRules.default
        let rules2 = GameRules()
        
        XCTAssertEqual(rules1, rules2,
                       "Конструктор по умолчанию должен давать те же значения что и .default")
    }
    
    // MARK: - Strict Rules
    
    func testStrict_DisallowsEditingOutsideParty() {
        let rules = GameRules.strict
        XCTAssertFalse(rules.canEditCharacterOutsideParty,
                       "Строгие правила должны блокировать редактирование")
    }
    
    // MARK: - Equatable
    
    func testEquatable_SameValues_AreEqual() {
        let rules1 = GameRules(canEditCharacterOutsideParty: true)
        let rules2 = GameRules(canEditCharacterOutsideParty: true)
        
        XCTAssertEqual(rules1, rules2)
    }
    
    func testEquatable_DifferentValues_AreNotEqual() {
        let rules1 = GameRules(canEditCharacterOutsideParty: true)
        let rules2 = GameRules(canEditCharacterOutsideParty: false)
        
        XCTAssertNotEqual(rules1, rules2)
    }
    
    // MARK: - Codable (важно для мультиплеера!)
    
    func testCodable_EncodesAndDecodesCorrectly() throws {
        let original = GameRules(canEditCharacterOutsideParty: false)
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GameRules.self, from: data)
        
        XCTAssertEqual(original, decoded,
                       "Правила должны корректно переживать encode/decode цикл")
    }
    
    func testCodable_DefaultValues_ArePreserved() throws {
        let original = GameRules.default
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GameRules.self, from: data)
        
        XCTAssertEqual(decoded.canEditCharacterOutsideParty, true)
    }
    
    // MARK: - Transmission via discoveryInfo
    
    func testCodable_CanBeConvertedToStringForBonjour() throws {
        // Именно так правила передаются через discoveryInfo в MultipeerConnectivity
        let rules = GameRules.strict
        
        let data = try JSONEncoder().encode(rules)
        let jsonString = String(data: data, encoding: .utf8)
        
        XCTAssertNotNil(jsonString,
                        "Правила должны конвертироваться в JSON-строку для Bonjour")
        
        // Обратная конвертация
        let backData = jsonString!.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GameRules.self, from: backData)
        
        XCTAssertEqual(decoded, rules)
    }
}