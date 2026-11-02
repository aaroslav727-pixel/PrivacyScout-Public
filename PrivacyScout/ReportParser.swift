import Foundation

/// Сырые агрегаты из файла отчёта iOS (формат NDJSON: одна JSON-запись на строку).
struct ParsedReport {
    /// bundleID -> категория -> число обращений
    var sensorCounts: [String: [SensorCategory: Int]] = [:]
    /// bundleID -> домен -> число запросов
    var domainHits: [String: [String: Int]] = [:]
    /// домен -> владелец (если iOS его указала)
    var domainOwners: [String: String] = [:]
    /// домены, которые сама iOS пометила как трекеры
    var flaggedDomains: Set<String> = []

    var lineCount = 0
    var skippedLines = 0
    var firstDate: Date?
    var lastDate: Date?

    var isEmpty: Bool { sensorCounts.isEmpty && domainHits.isEmpty }
}

enum ReportParser {

    static func parse(_ data: Data) -> ParsedReport {
        var result = ParsedReport()

        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()

        func date(from value: Any?) -> Date? {
            guard let text = value as? String else { return nil }
            return isoFractional.date(from: text) ?? isoPlain.date(from: text)
        }

        func register(_ d: Date?) {
            guard let d = d else { return }
            if let first = result.firstDate {
                if d < first { result.firstDate = d }
            } else {
                result.firstDate = d
            }
            if let last = result.lastDate {
                if d > last { result.lastDate = d }
            } else {
                result.lastDate = d
            }
        }

        // 10 == "\n"
        for slice in data.split(separator: 10, omittingEmptySubsequences: true) {
            result.lineCount += 1

            guard
                let object = try? JSONSerialization.jsonObject(with: Data(slice)),
                let dict = object as? [String: Any]
            else {
                result.skippedLines += 1
                continue
            }

            let type = dict["type"] as? String ?? ""

            switch type {

            case "access":
                // Обращение приложения к датчику или данным (геолокация, камера, ...).
                let kind = dict["kind"] as? String ?? ""
                if kind == "intervalEnd" { break } // считаем только начало обращения

                guard let categoryName = dict["category"] as? String,
                      let category = SensorCategory(rawValue: categoryName) else { break }

                var bundle: String?
                if let accessor = dict["accessor"] as? [String: Any] {
                    bundle = accessor["identifier"] as? String
                }
                if bundle == nil { bundle = dict["bundleID"] as? String }
                guard let bundleID = bundle, !bundleID.isEmpty else { break }

                result.sensorCounts[bundleID, default: [:]][category, default: 0] += 1
                register(date(from: dict["timestamp"] ?? dict["timeStamp"]))

            case "networkActivity":
                // Сетевая активность: с какими доменами связывалось приложение.
                guard let bundleID = dict["bundleID"] as? String,
                      let rawDomain = dict["domain"] as? String else { break }
                let domain = rawDomain.lowercased()
                if domain.isEmpty { break }

                let hits = (dict["hits"] as? NSNumber)?.intValue ?? 1
                result.domainHits[bundleID, default: [:]][domain, default: 0] += max(hits, 1)

                if let owner = dict["domainOwner"] as? String, !owner.isEmpty {
                    result.domainOwners[domain] = owner
                }
                if let domainType = dict["domainType"] as? String,
                   domainType.lowercased().contains("track") {
                    result.flaggedDomains.insert(domain)
                }

                register(date(from: dict["firstTimeStamp"]))
                register(date(from: dict["timeStamp"] ?? dict["timestamp"]))

            default:
                // Остальные типы записей (например, сайты из приложений) пока не используем.
                break
            }
        }

        return result
    }
}
