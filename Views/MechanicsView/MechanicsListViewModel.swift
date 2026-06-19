//
//  MechanicsListViewModel.swift
//  Clarity
//
//  Created by KEBAB on 19.06.2026.
//


import Foundation
import SwiftData
import Observation

/// ViewModel для списка механик
@Observable
class MechanicsListViewModel {
    /// Контекст SwiftData
    private let modelContext: ModelContext
    
    /// Текущий игровой шаблон
    private let gameTemplate: GameTemplate
    
    /// Список всех механик шаблона
    var mechanics: [Mechanic] {
        gameTemplate.mechanics.sorted { $0.name < $1.name }
    }
    
    init(modelContext: ModelContext, gameTemplate: GameTemplate) {
        self.modelContext = modelContext
        self.gameTemplate = gameTemplate
    }
    
    /// Создать новую механику
    func createMechanic() {
        let newMechanic = Mechanic(
            name: "Новая механика",
            trigger: .manual,
            gameTemplate: gameTemplate
        )
        
        gameTemplate.mechanics.append(newMechanic)
        modelContext.insert(newMechanic)
        
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при создании механики: \(error)")
        }
    }
    
    /// Удалить механику
    func deleteMechanic(_ mechanic: Mechanic) {
        gameTemplate.mechanics.removeAll { $0.id == mechanic.id }
        modelContext.delete(mechanic)
        
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при удалении механики: \(error)")
        }
    }
    
    /// Переключить активность механики
    func toggleMechanic(_ mechanic: Mechanic) {
        mechanic.isEnabled.toggle()
        
        do {
            try modelContext.save()
        } catch {
            print("Ошибка при переключении механики: \(error)")
        }
    }
}