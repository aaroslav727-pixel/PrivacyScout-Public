import SwiftUI
import UniformTypeIdentifiers

struct AnalysisView: View {
    @EnvironmentObject private var state: AppState
    @State private var showImporter = false
    @State private var filter: RiskFilter = .all

    enum RiskFilter: String, CaseIterable, Identifiable {
        case all, high, medium, low

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "Все"
            case .high: return "Высокий"
            case .medium: return "Средний"
            case .low: return "Низкий"
            }
        }

        func matches(_ level: RiskLevel) -> Bool {
            switch self {
            case .all: return true
            case .high: return level == .high
            case .medium: return level == .medium
            case .low: return level == .low
            }
        }
    }

    private var filtered: [AppReport] {
        state.visibleReports.filter { filter.matches($0.level) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if state.isLoading {
                    ProgressView("Анализирую отчёт…")
                } else if state.reports.isEmpty {
                    EmptyStateView(onImport: { showImporter = true })
                } else {
                    resultsList
                }
            }
            .navigationTitle("Privacy Scout")
            .toolbar {
                if !state.reports.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showImporter = true
                            } label: {
                                Label("Импортировать другой отчёт", systemImage: "square.and.arrow.down")
                            }
                            Toggle(isOn: $state.showSystemApps) {
                                Label("Показывать системные", systemImage: "gearshape")
                            }
                            Button(role: .destructive) {
                                state.reset()
                            } label: {
                                Label("Очистить результаты", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.json, .plainText, .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task { await state.importFile(url) }
                    }
                case .failure(let error):
                    state.errorMessage = error.localizedDescription
                }
            }
            .alert(
                "Ошибка",
                isPresented: Binding(
                    get: { state.errorMessage != nil },
                    set: { if !$0 { state.errorMessage = nil } }
                ),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(state.errorMessage ?? "") }
            )
        }
    }

    // MARK: Результаты

    private var resultsList: some View {
        List {
            Section {
                SummaryCard(reports: state.visibleReports,
                            period: state.periodText,
                            isDemo: state.isDemo)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                Picker("Фильтр", selection: $filter) {
                    ForEach(RiskFilter.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            Section("Приложения (\(filtered.count))") {
                if filtered.isEmpty {
                    Text("В этой категории приложений нет.")
                        .foregroundStyle(.secondary)
                }
                ForEach(filtered) { report in
                    NavigationLink {
                        AppDetailView(report: report)
                    } label: {
                        AppRow(report: report)
                    }
                }
            }
        }
    }
}

// MARK: - Сводка

private struct SummaryCard: View {
    let reports: [AppReport]
    let period: String?
    let isDemo: Bool

    private func count(_ level: RiskLevel) -> Int {
        reports.filter { $0.level == level }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isDemo {
                Label("Демо-данные: приложения вымышленные", systemImage: "flask.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
            }
            if let period = period {
                Text("Период отчёта: \(period)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                stat(.high)
                stat(.medium)
                stat(.low)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func stat(_ level: RiskLevel) -> some View {
        VStack(spacing: 4) {
            Text("\(count(level))")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(level.color)
            Text(level.title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(level.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Строка списка

private struct AppRow: View {
    let report: AppReport

    var body: some View {
        HStack(spacing: 12) {
            ScoreRing(score: report.score, level: report.level)

            VStack(alignment: .leading, spacing: 4) {
                Text(report.displayName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    ForEach(report.usedSensors) { sensor in
                        Image(systemName: sensor.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !report.trackerContacts.isEmpty {
                        Label("\(report.trackerOwners.count)", systemImage: "eye.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            LevelBadge(level: report.level)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Пустой экран с инструкцией

private struct EmptyStateView: View {
    @EnvironmentObject private var state: AppState
    let onImport: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)
                    .padding(.top, 24)

                Text("Кто за вами следит?")
                    .font(.title2.bold())

                Text("iOS не позволяет приложениям проверять другие приложения, зато сама ведёт скрытый журнал: кто обращался к камере, микрофону, геолокации и с какими серверами связывался. Privacy Scout читает этот журнал и оценивает риск.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 14) {
                    stepRow(1, "Откройте Настройки → Конфиденциальность и безопасность → «Отчёт о конфиденциальности приложений» и включите запись активности.")
                    stepRow(2, "Подождите несколько дней, пока соберутся данные.")
                    stepRow(3, "В том же разделе нажмите «Сохранить активность приложений» и сохраните файл в «Файлы».")
                    stepRow(4, "Вернитесь сюда и импортируйте этот файл.")
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button(action: onImport) {
                    Label("Импортировать отчёт", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    state.loadDemo()
                } label: {
                    Label("Посмотреть на демо-данных", systemImage: "flask")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Label("Файл обрабатывается только на устройстве и никуда не отправляется.", systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
