//  AbilityScoresTests.swift
//  ClarityTests
//
//  Created by KEBAB on 05.06.2026.
//
import XCTest
@testable import Clarity

final class AbilityScoresTests: XCTestCase {
    
    func testModifier_ForValue10_Returns0() {
        var scores = AbilityScores()  // ✅ var вместо let
        scores.strength = 10
        XCTAssertEqual(scores.modifier(for: \.strength), 0)
    }
    
    func testModifier_ForValue8_ReturnsMinus1() {
        var scores = AbilityScores()
        scores.strength = 8
        XCTAssertEqual(scores.modifier(for: \.strength), -1)
    }
    
    func testModifier_ForValue9_ReturnsMinus1() {
        var scores = AbilityScores()
        scores.strength = 9
        XCTAssertEqual(scores.modifier(for: \.strength), -1,
                       "Характеристика 9 должна давать модификатор -1 по правилам D&D 5e")
    }
    
    func testModifier_ForValue15_ReturnsPlus2() {
        var scores = AbilityScores()
        scores.strength = 15
        XCTAssertEqual(scores.modifier(for: \.strength), 2)
    }
    
    func testModifier_ForValue20_ReturnsPlus5() {
        var scores = AbilityScores()
        scores.strength = 20
        XCTAssertEqual(scores.modifier(for: \.strength), 5)
    }
    
    func testReset_SetsAllToMin() {
        var scores = AbilityScores()
        scores.strength = 15
        scores.dexterity = 14
        scores.constitution = 13
        scores.intelligence = 12
        scores.wisdom = 11
        scores.charisma = 10
        
        scores.reset()
        
        XCTAssertEqual(scores.strength, Constants.Stat.minValue)
        XCTAssertEqual(scores.dexterity, Constants.Stat.minValue)
        XCTAssertEqual(scores.constitution, Constants.Stat.minValue)
        XCTAssertEqual(scores.intelligence, Constants.Stat.minValue)
        XCTAssertEqual(scores.wisdom, Constants.Stat.minValue)
        XCTAssertEqual(scores.charisma, Constants.Stat.minValue)
    }
}
