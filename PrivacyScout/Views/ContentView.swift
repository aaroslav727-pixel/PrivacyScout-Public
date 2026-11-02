import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AnalysisView()
                .tabItem { Label("Анализ", systemImage: "shield.lefthalf.filled") }

            TipsView()
                .tabItem { Label("Советы", systemImage: "lightbulb.fill") }

            AboutView()
                .tabItem { Label("О приложении", systemImage: "info.circle") }
        }
    }
}

// MARK: - Общие компоненты

struct ScoreRing: View {
    let score: Int
    let level: RiskLevel
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            Circle()
                .stroke(level.color.opacity(0.2), lineWidth: size * 0.12)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(level.color, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
        }
        .frame(width: size, height: size)
    }
}

struct LevelBadge: View {
    let level: RiskLevel

    var body: some View {
        Label(level.title, systemImage: level.icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(level.color.opacity(0.15))
            .foregroundStyle(level.color)
            .clipShape(Capsule())
    }
}
