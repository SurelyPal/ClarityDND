import SwiftUI
import SwiftData

// MARK: - Корневой экран (создаёт CharacterStore и передаёт его всему приложению)

struct RootView: View {
    
    // Забираем контекст SwiftData, который подключён в ClarityApp
    @Environment(\.modelContext) private var modelContext
    
    // Храним CharacterStore как @State (он будет жить, пока жив RootView)
    @State private var store: CharacterStore?
    
    var body: some View {
        ZStack {
            // Фон в стиле Dark Souls
            Color.dsBackground
                .ignoresSafeArea()
            
            if let store = store {
                // 🆕 Как только store создан — показываем ContentView 
                // и ВЛИВАЕМ store в Environment для ВСЕХ дочерних экранов
                ContentView()
                    .environmentObject(store)
            } else {
                // Экран загрузки (показывается долю секунды при старте)
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.dsGold)
                        .scaleEffect(1.5)
                    
                    Text("Открываем книгу судеб...")
                        .font(.system(size: 14))
                        .foregroundColor(.dsTextDim)
                        .tracking(1)
                }
                .onAppear {
                    // Создаём CharacterStore, передавая ему context из SwiftData
                    store = CharacterStore(context: modelContext)
                    print("✅ CharacterStore создан в RootView и передан в Environment")
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
        .modelContainer(for: DNDCharacter.self)
}