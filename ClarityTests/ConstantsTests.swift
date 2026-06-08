//
//  ConstantsTests.swift
//  ClarityTests
//
//  Created by KEBAB on 05.06.2026.
//
import XCTest
@testable import Clarity

final class ConstantsTests: XCTestCase {
    
    // MARK: - Stat Modifier
    
    func testStatModifier_EvenValues() {
        XCTAssertEqual(Constants.Stat.modifier(for: 10), 0)
        XCTAssertEqual(Constants.Stat.modifier(for: 12), 1)
        XCTAssertEqual(Constants.Stat.modifier(for: 14), 2)
        XCTAssertEqual(Constants.Stat.modifier(for: 20), 5)
    }
    
    func testStatModifier_OddValues() {
        XCTAssertEqual(Constants.Stat.modifier(for: 11), 0)   // (11-10)/2 = 0
        XCTAssertEqual(Constants.Stat.modifier(for: 13), 1)   // (13-10)/2 = 1
        XCTAssertEqual(Constants.Stat.modifier(for: 15), 2)
    }
    
    func testStatModifier_NegativeValues() {
        XCTAssertEqual(Constants.Stat.modifier(for: 8), -1)
        XCTAssertEqual(Constants.Stat.modifier(for: 6), -2)
        XCTAssertEqual(Constants.Stat.modifier(for: 4), -3)  // 4 даёт -3
        XCTAssertEqual(Constants.Stat.modifier(for: 3), -4)  // 3 даёт -4
        XCTAssertEqual(Constants.Stat.modifier(for: 1), -5)  // 1 даёт -5
    }
    
    // MARK: - Formatted Modifier
    
    func testFormattedModifier_Positive_HasPlusSign() {
        XCTAssertEqual(Constants.Stat.formattedModifier(2), "+2")
        XCTAssertEqual(Constants.Stat.formattedModifier(0), "+0")
    }
    
    func testFormattedModifier_Negative_HasMinusSign() {
        XCTAssertEqual(Constants.Stat.formattedModifier(-1), "-1")
        XCTAssertEqual(Constants.Stat.formattedModifier(-3), "-3")
    }
    
    // MARK: - Point Buy Cost
    
    func testCostToIncrease_From8to9_Costs1() {
        XCTAssertEqual(Constants.Stat.costToIncrease(from: 8), 1)
    }
    
    func testCostToIncrease_From13to14_Costs2() {
        // 14 стоит 7, 13 стоит 5 → разница 2
        XCTAssertEqual(Constants.Stat.costToIncrease(from: 13), 2)
    }
    
    func testCostToIncrease_From14to15_Costs2() {
        // 15 стоит 9, 14 стоит 7 → разница 2
        XCTAssertEqual(Constants.Stat.costToIncrease(from: 14), 2)
    }
    
    // MARK: - Stress Labels
    
    func testStressLabels_AllLevelsHaveNames() {
        for level in Constants.Stress.levels {
            let label = Constants.Stress.label(for: level)
            XCTAssertFalse(label.isEmpty, "Для уровня \(level) должна быть подпись")
        }
    }
}
