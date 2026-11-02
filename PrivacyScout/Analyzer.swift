import Foundation

/// ПУБЛИЧНАЯ УПРОЩЁННАЯ ВЕРСИЯ.
/// Полная модель оценки риска (веса, опасные сочетания, эвристики) находится
/// в закрытой части проекта и в этот репозиторий не входит.
/// Здесь — базовая оценка: датчики + число сторонних трекеров.
enum Analyzer {

    static func build(from parsed: ParsedReport) -> [AppReport] {
        var bundles = Set(parsed.sensorCounts.keys)
        bundles.formUnion(parsed.domainHits.keys)

        let reports = bundles.map { analyze(bundleID: $0, parsed: parsed) }
        return reports.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.displayName < rhs.displayName
        }
    }

    private static func analyze(bundleID: String, parsed: ParsedReport) -> AppReport {
        let sensors = parsed.sensorCounts[bundleID] ?? [:]
        let hits = parsed.domainHits[bundleID] ?? [:]

        var contacts: [DomainContact] = []
        for (domain, count) in hits {
            let tracker = TrackerDatabase.lookup(domain)
            var owner = tracker?.owner ?? parsed.domainOwners[domain]
            if owner == nil && TrackerDatabase.isApple(domain) { owner = "Apple" }
            contacts.append(DomainContact(domain: domain, hits: count, owner: owner, tracker: tracker))
        }
        contacts.sort { lhs, rhs in
            let l = lhs.tracker != nil ? 1 : 0
            let r = rhs.tracker != nil ? 1 : 0
            if l != r { return l > r }
            return lhs.hits > rhs.hits
        }

        var score = 0
        for (category, count) in sensors where count > 0 {
            score += category.weight
        }
        let trackers = contacts.compactMap { $0.tracker }
        score += min(trackers.count * 8, 50)
        score = max(0, min(100, score))

        var findings: [Finding] = []

        if !trackers.isEmpty {
            let owners = Set(trackers.map { $0.owner }).sorted().joined(separator: ", ")
            findings.append(Finding(
                severity: trackers.count >= 3 ? .medium : .low,
                title: "Найдены сторонние трекеры",
                detail: "Приложение связывалось с известными трекерами: \(owners)."
            ))
        }

        let usedSensors = SensorCategory.allCases.filter { (sensors[$0] ?? 0) > 0 }
        if !usedSensors.isEmpty {
            let names = usedSensors.map { $0.title }.joined(separator: ", ")
            findings.append(Finding(
                severity: .low,
                title: "Обращения к данным и датчикам",
                detail: "Приложение использовало: \(names)."
            ))
        }

        if findings.isEmpty {
            findings.append(Finding(
                severity: .low,
                title: "Подозрительного не найдено",
                detail: "В этом отчёте нет известных трекеров. Это не гарантия: база трекеров неполная."
            ))
        }

        return AppReport(
            bundleID: bundleID,
            displayName: AppNames.displayName(for: bundleID),
            isSystem: bundleID.hasPrefix("com.apple."),
            sensors: sensors,
            domains: contacts,
            score: score,
            level: RiskLevel.from(score: score),
            findings: findings.sorted { $0.severity > $1.severity }
        )
    }

    // MARK: - Рекомендации по конкретному приложению

    static func recommendations(for report: AppReport) -> [String] {
        var tips: [String] = []
        let sensors = report.sensors

        if (sensors[.location] ?? 0) > 0 {
            tips.append("Настройки → Конфиденциальность и безопасность → Службы геолокации → «\(report.displayName)»: выберите «При использовании» или «Никогда» и выключите «Точная геопозиция».")
        }
        if (sensors[.microphone] ?? 0) > 0 {
            tips.append("Настройки → Конфиденциальность и безопасность → Микрофон: выключите доступ, если приложение не записывает голос или не звонит.")
        }
        if (sensors[.camera] ?? 0) > 0 {
            tips.append("Настройки → Конфиденциальность и безопасность → Камера: оставьте доступ только тем приложениям, которым нужно фото или видео.")
        }
        if (sensors[.contacts] ?? 0) > 0 {
            tips.append("Настройки → Конфиденциальность и безопасность → Контакты: запретите доступ или оставьте «Ограниченный доступ» (iOS 18 и новее).")
        }
        if (sensors[.photos] ?? 0) > 0 {
            tips.append("Настройки → Конфиденциальность и безопасность → Фото: выберите «Выбранные фото» вместо «Все фото».")
        }
        if !report.trackerContacts.isEmpty {
            tips.append("Настройки → Конфиденциальность и безопасность → Отслеживание: выключите переключатель для этого приложения и общий запрос на отслеживание.")
            tips.append("Если приложение работает и в браузере, пользуйтесь сайтом: у вебсайта меньше доступа к датчикам, а Safari блокирует часть трекеров.")
        }
        if report.level == .high {
            tips.append("Рассмотрите удаление приложения или замену на альтернативу без рекламных SDK. Перед удалением можно запросить удаление аккаунта и данных у разработчика.")
        }
        if tips.isEmpty {
            tips.append("Действий не требуется. Просто периодически проверяйте отчёт заново.")
        }
        return tips
    }
}

// MARK: - Красивые названия приложений

enum AppNames {
    private static let known: [String: String] = [
        "com.facebook.Facebook": "Facebook",
        "com.burbn.instagram": "Instagram",
        "com.zhiliaoapp.musically": "TikTok",
        "ph.telegra.Telegraph": "Telegram",
        "net.whatsapp.WhatsApp": "WhatsApp",
        "com.google.chrome.ios": "Chrome",
        "com.google.Maps": "Google Карты",
        "com.toyopagroup.picaboo": "Snapchat",
        "com.atebits.Tweetie2": "X (Twitter)",
        "com.hammerandchisel.discord": "Discord",
        "com.spotify.client": "Spotify",
        "com.netflix.Netflix": "Netflix",
        "com.apple.mobilesafari": "Safari",
        "com.apple.camera": "Камера",
        "com.apple.Maps": "Карты",
        "com.apple.MobileSMS": "Сообщения",
        "com.apple.mobilephone": "Телефон",
        "com.apple.Preferences": "Настройки",
        "com.apple.Photos": "Фото",
        "com.apple.weather": "Погода",
        // Демо-приложения
        "demo.torch": "Фонарик «Яркий»",
        "demo.weather": "Погода Плюс",
        "demo.messenger": "Мессенджер Чат",
        "demo.notes": "Заметки",
        "demo.game": "Космо-аркада",
        "demo.bank": "Мой Банк"
    ]

    static func displayName(for bundleID: String) -> String {
        if let name = known[bundleID] { return name }
        guard let last = bundleID.split(separator: ".").last else { return bundleID }
        let text = String(last)
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
