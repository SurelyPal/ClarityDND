//
//  TarotCardTests.swift
//  Clarity
//
//  Created by KEBAB on 07.06.2026.
//


//
//  TarotCardTests.swift
//  ClarityTests
//
//  Created by AI on 07.06.2026.
//
import XCTest
@testable import Clarity

final class TarotCardTests: XCTestCase {
    
    // MARK: - Initial State
    
    func testNewCard_HasDefaultValues() {
        let card = TarotCard()
        
        XCTAssertTrue(card.name.isEmpty)
        XCTAssertTrue(card.arcana.isEmpty)
        XCTAssertTrue(card.effect.isEmpty)
        XCTAssertFalse(card.isRevealed)
        XCTAssertEqual(card.usesLeft, 1)
    }
    
    // MARK: - canUse
    
    func testCanUse_WithUsesLeft_ReturnsTrue() {
        var card = TarotCard()
        card.usesLeft = 3
        XCTAssertTrue(card.canUse)
    }
    
    func testCanUse_WithOneUseLeft_ReturnsTrue() {
        var card = TarotCard()
        card.usesLeft = 1
        XCTAssertTrue(card.canUse)
    }
    
    func testCanUse_WithZeroUses_ReturnsFalse() {
        var card = TarotCard()
        card.usesLeft = 0
        XCTAssertFalse(card.canUse)
    }
    
    func testCanUse_WithNegativeUses_ReturnsFalse() {
        var card = TarotCard()
        card.usesLeft = -1
        XCTAssertFalse(card.canUse, "Отрицательные usesLeft — edge case")
    }
    
    // MARK: - use()
    
    func testUse_DecreasesUsesLeft() {
        var card = TarotCard()
        card.usesLeft = 3
        
        card.use()
        
        XCTAssertEqual(card.usesLeft, 2)
    }
    
    func testUse_WhenZero_DoesNotGoNegative() {
        var card = TarotCard()
        card.usesLeft = 0
        
        card.use()
        
        XCTAssertEqual(card.usesLeft, 0,
                       "Использование без зарядов не должно уходить в минус")
    }
    
    func testUse_MultipleTimes_WorksCorrectly() {
        var card = TarotCard()
        card.usesLeft = 3
        
        card.use()
        card.use()
        card.use()
        
        XCTAssertEqual(card.usesLeft, 0)
        
        // Четвёртая попытка — не должна сломать
        card.use()
        XCTAssertEqual(card.usesLeft, 0)
    }
    
    // MARK: - isFaceDown
    
    func testIsFaceDown_WhenRevealed_IsFalse() {
        var card = TarotCard()
        card.isRevealed = true
        XCTAssertFalse(card.isFaceDown)
    }
    
    func testIsFaceDown_WhenNotRevealed_IsTrue() {
        var card = TarotCard()
        card.isRevealed = false
        XCTAssertTrue(card.isFaceDown)
    }
    
    // MARK: - Starter Deck
    
    func testStarterDeck_HasCorrectCount() {
        let deck = TarotCard.starterDeck
        XCTAssertEqual(deck.count, 7, "В стартовой колоде должно быть 7 карт")
    }
    
    func testStarterDeck_AllCardsHaveNames() {
        let deck = TarotCard.starterDeck
        for card in deck {
            XCTAssertFalse(card.name.isEmpty,
                           "Карта \(card) не имеет имени")
        }
    }
    
    func testStarterDeck_AllCardsHaveArcana() {
        let deck = TarotCard.starterDeck
        for card in deck {
            XCTAssertFalse(card.arcana.isEmpty,
                           "Карта \(card.name) не имеет аркана")
        }
    }
    
    func testStarterDeck_AllCardsHaveEffects() {
        let deck = TarotCard.starterDeck
        for card in deck {
            XCTAssertFalse(card.effect.isEmpty,
                           "Карта \(card.name) не имеет эффекта")
        }
    }
    
    func testStarterDeck_AllCardsHaveUniqueIDs() {
        let deck = TarotCard.starterDeck
        let ids = deck.map { $0.id }
        let uniqueIDs = Set(ids)
        
        XCTAssertEqual(ids.count, uniqueIDs.count,
                       "Все карты в колоде должны иметь уникальные ID")
    }
    
    // MARK: - Identifiable
    
    func testTwoCards_HaveDifferentIDs() {
        let card1 = TarotCard()
        let card2 = TarotCard()
        XCTAssertNotEqual(card1.id, card2.id)
    }
}