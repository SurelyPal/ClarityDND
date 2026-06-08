//
//  PartyMemberTests.swift
//  Clarity
//
//  Created by KEBAB on 07.06.2026.
//


//
//  PartyMemberTests.swift
//  ClarityTests
//
//  Created by AI on 07.06.2026.
import SwiftUI
import XCTest
import MultipeerConnectivity
@testable import Clarity

final class PartyMemberTests: XCTestCase {
    
    // MARK: - Helpers
    
    private func makeMember(
        currentHP: Int = 10,
        maxHP: Int = 10,
        stats: AbilityScores? = nil,
        isConnected: Bool = true
    ) -> PartyMember {
        PartyMember(
            id: UUID(),
            peerID: MCPeerID(displayName: "TestPeer"),
            name: "Тестовый герой",
            race: .human,
            characterClass: "Воин",
            level: 1,
            currentHP: currentHP,
            maxHP: maxHP,
            stress: 0,
            avatarData: nil,
            isConnected: isConnected
        )
    }
    
    // MARK: - hpFraction
    
    func testHpFraction_FullHP_Returns1() {
        let member = makeMember(currentHP: 10, maxHP: 10)
        XCTAssertEqual(member.hpFraction, 1.0, accuracy: 0.001)
    }
    
    func testHpFraction_HalfHP_Returns0_5() {
        let member = makeMember(currentHP: 5, maxHP: 10)
        XCTAssertEqual(member.hpFraction, 0.5, accuracy: 0.001)
    }
    
    func testHpFraction_ZeroHP_Returns0() {
        let member = makeMember(currentHP: 0, maxHP: 10)
        XCTAssertEqual(member.hpFraction, 0.0, accuracy: 0.001)
    }
    
    func testHpFraction_ZeroMaxHP_Returns0() {
        let member = makeMember(currentHP: 5, maxHP: 0)
        XCTAssertEqual(member.hpFraction, 0.0,
                       "При maxHP=0 должна быть защита от деления на ноль")
    }
    
    // MARK: - hpColor
    
    func testHpColor_FullHP_ReturnsGold() {
        let member = makeMember(currentHP: 10, maxHP: 10)
        XCTAssertEqual(member.hpColor, Color.dsGold)
    }
    
    func testHpColor_AboveHalf_ReturnsGold() {
        let member = makeMember(currentHP: 6, maxHP: 10)
        XCTAssertEqual(member.hpColor, Color.dsGold)
    }
    
    func testHpColor_ExactlyHalf_ReturnsOrange() {
        let member = makeMember(currentHP: 5, maxHP: 10)
        XCTAssertEqual(member.hpColor, .orange)
    }
    
    func testHpColor_Between25And50_ReturnsOrange() {
        let member = makeMember(currentHP: 3, maxHP: 10)
        XCTAssertEqual(member.hpColor, .orange)
    }
    
    func testHpColor_Exactly25Percent_ReturnsRed() {
        let member = makeMember(currentHP: 2, maxHP: 8)  // 25%
        XCTAssertEqual(member.hpColor, Color.dsRed)
    }
    
    func testHpColor_Below25_ReturnsRed() {
        let member = makeMember(currentHP: 1, maxHP: 10)
        XCTAssertEqual(member.hpColor, Color.dsRed)
    }
    
    func testHpColor_ZeroHP_ReturnsRed() {
        let member = makeMember(currentHP: 0, maxHP: 10)
        XCTAssertEqual(member.hpColor, Color.dsRed)
    }
    
    // MARK: - hasFullProfile
    
    func testHasFullProfile_WithoutStats_ReturnsFalse() {
        var member = makeMember()
        member.stats = nil
        XCTAssertFalse(member.hasFullProfile)
    }
    
    func testHasFullProfile_WithStats_ReturnsTrue() {
        var member = makeMember()
        member.stats = AbilityScores()
        XCTAssertTrue(member.hasFullProfile)
    }
    
    // MARK: - peerID reconstruction
    
    func testPeerID_ReconstructsFromDisplayName() {
        let originalName = "Игрок Иван"
        let peerID = MCPeerID(displayName: originalName)
        
        let member = PartyMember(
            id: UUID(),
            peerID: peerID,
            name: "Иван",
            race: .human,
            characterClass: "Воин",
            level: 1,
            currentHP: 10,
            maxHP: 10,
            stress: 0,
            avatarData: nil
        )
        
        XCTAssertEqual(member.peerID.displayName, originalName,
                       "peerID должен восстанавливаться из displayName")
    }
    
    // MARK: - Default values
    
    func testMember_IsConnectedByDefault() {
        let member = makeMember()
        XCTAssertTrue(member.isConnected)
    }
    
    func testMember_HasLastSeenDate() {
        let member = makeMember()
        // lastSeen должен быть установлен (не равен distantPast)
        XCTAssertNotEqual(member.lastSeen, Date.distantPast)
    }
}
