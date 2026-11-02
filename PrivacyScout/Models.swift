import SwiftUI

// MARK: - Уровень риска

enum RiskLevel: Int, Comparable, CaseIterable, Identifiable {
    case low = 0
    case medium = 1
    case high = 2

    var id: Int { rawValue }

    static func < (lhs: RiskLevel, rhs: RiskLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .low: return "Низкий"
        case .medium: return "Средний"
        case .high: return "Высокий"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .high: return "xmark.shield.fill"
        }
    }

    static func from(score: Int) -> RiskLevel {
        if score < 25 { return .low }
        if score < 55 { return .medium }
        return .high
    }
}

// MARK: - Датчики и данные, к которым обращалось приложение

enum SensorCategory: String, CaseIterable, Identifiable {
    case location
    case camera
    case microphone
    case photos
    case contacts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location: return "Геолокация"
        case .camera: return "Камера"
        case .microphone: return "Микрофон"
        case .photos: return "Фото"
        case .contacts: return "Контакты"
        }
    }

    var icon: String {
        switch self {
        case .location: return "location.fill"
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        case .photos: return "photo.fill"
        case .contacts: return "person.2.fill"
        }
    }

    /// Вес в итоговой оценке риска.
    var weight: Int {
        switch self {
        case .location: return 10
        case .microphone: return 10
        case .contacts: return 8
        case .camera: return 6
        case .photos: return 5
        }
    }
}

// MARK: - Трекеры

enum TrackerKind: String {
    case advertising
    case analytics
    case attribution
    case social
    case fingerprinting
    case dataBroker
    case flagged

    var title: String {
        switch self {
        case .advertising: return "Реклама"
        case .analytics: return "Аналитика"
        case .attribution: return "Атрибуция рекламы"
        case .social: return "Соцсеть / SDK"
        case .fingerprinting: return "Отпечаток устройства"
        case .dataBroker: return "Брокер геоданных"
        case .flagged: return "Трекер (по оценке iOS)"
        }
    }

    var weight: Int {
        switch self {
        case .dataBroker: return 30
        case .fingerprinting: return 8
        case .advertising: return 8
        case .attribution: return 6
        case .social: return 6
        case .flagged: return 6
        case .analytics: return 4
        }
    }

    var icon: String {
        switch self {
        case .advertising: return "megaphone.fill"
        case .analytics: return "chart.bar.fill"
        case .attribution: return "link"
        case .social: return "person.crop.circle.badge.exclamationmark"
        case .fingerprinting: return "touchid"
        case .dataBroker: return "mappin.and.ellipse"
        case .flagged: return "eye.fill"
        }
    }
}

struct TrackerInfo {
    let owner: String
    let kind: TrackerKind
}

// MARK: - Сетевые контакты

struct DomainContact: Identifiable {
    var id: String { domain }
    let domain: String
    let hits: Int
    let owner: String?
    let tracker: TrackerInfo?
}

// MARK: - Выводы анализа

struct Finding: Identifiable {
    let id = UUID()
    let severity: RiskLevel
    let title: String
    let detail: String
}

struct AppReport: Identifiable {
    var id: String { bundleID }
    let bundleID: String
    let displayName: String
    let isSystem: Bool
    let sensors: [SensorCategory: Int]
    let domains: [DomainContact]
    let score: Int
    let level: RiskLevel
    let findings: [Finding]

    var trackerContacts: [DomainContact] {
        domains.filter { $0.tracker != nil }
    }

    var trackerOwners: [String] {
        let owners = trackerContacts.compactMap { $0.tracker?.owner }
        return Array(Set(owners)).sorted()
    }

    var usedSensors: [SensorCategory] {
        SensorCategory.allCases.filter { (sensors[$0] ?? 0) > 0 }
    }
}
