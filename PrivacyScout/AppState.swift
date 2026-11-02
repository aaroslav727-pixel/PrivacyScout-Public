import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var reports: [AppReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDemo = false
    @Published var periodText: String?
    @Published var showSystemApps = false

    private typealias LoadResult = Result<(ParsedReport, [AppReport]), Error>

    /// Читает и анализирует файл отчёта. Всё происходит на устройстве, без сети.
    func importFile(_ url: URL) async {
        isLoading = true
        errorMessage = nil

        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted { url.stopAccessingSecurityScopedResource() }
        }

        let result: LoadResult = await Task.detached(priority: .userInitiated) { () -> LoadResult in
            do {
                let data = try Data(contentsOf: url)
                let parsed = ReportParser.parse(data)
                return .success((parsed, Analyzer.build(from: parsed)))
            } catch {
                return .failure(error)
            }
        }.value

        isLoading = false

        switch result {
        case .failure(let error):
            errorMessage = "Не удалось прочитать файл: \(error.localizedDescription)"
        case .success(let (parsed, built)):
            if parsed.isEmpty {
                errorMessage = "В файле не найдено данных об активности приложений. Нужен файл, который iOS создаёт кнопкой «Сохранить активность приложений» в отчёте о конфиденциальности."
                return
            }
            reports = built
            isDemo = false
            periodText = Self.period(parsed)
        }
    }

    func loadDemo() {
        let parsed = DemoData.parsed()
        reports = Analyzer.build(from: parsed)
        isDemo = true
        periodText = Self.period(parsed)
        errorMessage = nil
    }

    func reset() {
        reports = []
        isDemo = false
        periodText = nil
        errorMessage = nil
    }

    var visibleReports: [AppReport] {
        reports.filter { showSystemApps || !$0.isSystem }
    }

    private static func period(_ parsed: ParsedReport) -> String? {
        guard let first = parsed.firstDate, let last = parsed.lastDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "\(formatter.string(from: first)) — \(formatter.string(from: last))"
    }
}
