import XCTest
import SwiftData
@testable import Clarity

@MainActor  // 🔽 ВАЖНО: добавь эту строку
final class RuleEngineTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var ruleEngine: RuleEngine!
    
    override func setUp() {
        super.setUp()
        
        // Создаём in-memory контейнер для тестов
        container = try! ModelContainer(
            for: Mechanic.self, Action.self, DNDCharacter.self, FieldValue.self, GameTemplate.self, FieldDefinition.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        ruleEngine = RuleEngine(modelContext: context)
    }
    
    override func tearDown() {
        container = nil
        context = nil
        ruleEngine = nil
        super.tearDown()
    }
    
    // MARK: - Тесты
    
    func testIncrementField() {
        // Создаём шаблон (нужен для FieldDefinition)
        let template = GameTemplate(
            name: "Test Template",
            templateDescription: "Test",
            isBuiltIn: false
        )
        context.insert(template)
        
        // Создаём определение поля stress
        let stressDefinition = FieldDefinition(
            name: "Стресс",
            key: "stress",
            fieldType: .integer,
            defaultValue: "0"
        )
        stressDefinition.gameTemplate = template
        context.insert(stressDefinition)
        
        // Создаём персонажа БЕЗ параметров (или с нужными по твоему инициализатору)
        let character = DNDCharacter()  // 🔽 Замени на свой инициализатор!
        character.name = "Тестовый персонаж"
        context.insert(character)
        
        // Создаём значение поля stress = 5
        let fieldValue = FieldValue(
            characterID: character.id,
            fieldKey: "stress",
            intValue: 5
        )
        character.fieldValues.append(fieldValue)
        context.insert(fieldValue)
        
        // Создаём механику с одним действием
        let mechanic = Mechanic(name: "Тест увеличения", trigger: .manual)
        mechanic.gameTemplate = template
        context.insert(mechanic)
        
        // Параметры: увеличить stress на 2
        let params = IncrementFieldParameters(fieldKey: "stress", amount: 2)
        let action = Action(
            mechanic: mechanic,
            order: 0,
            type: .incrementField,
            parameters: try! JSONEncoder().encode(params)
        )
        mechanic.actions.append(action)
        context.insert(action)
        
        // Выполняем механику
        ruleEngine.execute(mechanic: mechanic, character: character)
        
        // Проверяем результат
        XCTAssertEqual(fieldValue.intValue, 7, "Значение stress должно быть 7")
    }
    
    func testSetField() {
        let template = GameTemplate(
            name: "Test Template",
            templateDescription: "Test",
            isBuiltIn: false
        )
        context.insert(template)
        
        // Создаём персонажа
        let character = DNDCharacter()  // 🔽 Замени на свой инициализатор!
        character.name = "Тест"
        context.insert(character)
        
        // Создаём механику
        let mechanic = Mechanic(name: "Тест установки", trigger: .manual)
        mechanic.gameTemplate = template
        context.insert(mechanic)
        
        // Параметры: установить hp = 10
        let params = SetFieldParameters(fieldKey: "hp", value: 10)
        let action = Action(
            mechanic: mechanic,
            order: 0,
            type: .setField,
            parameters: try! JSONEncoder().encode(params)
        )
        mechanic.actions.append(action)
        context.insert(action)
        
        // Выполняем
        ruleEngine.execute(mechanic: mechanic, character: character)
        
        // Проверяем
        let hpField = character.fieldValues.first { $0.fieldKey == "hp" }
        XCTAssertNotNil(hpField, "Поле hp должно быть создано")
        XCTAssertEqual(hpField?.intValue, 10, "Значение hp должно быть 10")
    }
    
    func testDecrementField() {
        let template = GameTemplate(
            name: "Test Template",
            templateDescription: "Test",
            isBuiltIn: false
        )
        context.insert(template)
        
        let character = DNDCharacter()
        character.name = "Тест"
        context.insert(character)
        
        // Создаём поле с начальным значением 10
        let fieldValue = FieldValue(
            characterID: character.id,
            fieldKey: "hp",
            intValue: 10
        )
        character.fieldValues.append(fieldValue)
        context.insert(fieldValue)
        
        let mechanic = Mechanic(name: "Тест уменьшения", trigger: .manual)
        mechanic.gameTemplate = template
        context.insert(mechanic)
        
        let params = DecrementFieldParameters(fieldKey: "hp", amount: 3)
        let action = Action(
            mechanic: mechanic,
            order: 0,
            type: .decrementField,
            parameters: try! JSONEncoder().encode(params)
        )
        mechanic.actions.append(action)
        context.insert(action)
        
        ruleEngine.execute(mechanic: mechanic, character: character)
        
        XCTAssertEqual(fieldValue.intValue, 7, "Значение hp должно быть 7")
    }
}
