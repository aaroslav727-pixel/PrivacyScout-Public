import Foundation

/// ПУБЛИЧНАЯ ЗАГЛУШКА с минимальным набором доменов (достаточно для демо-режима).
/// Полная база трекеров находится в закрытой части проекта и в этот репозиторий не входит.
enum TrackerDatabase {

    /// Ищет домен или его родительские домены (graph.facebook.com -> facebook.com).
    static func lookup(_ host: String) -> TrackerInfo? {
        var candidate = host.lowercased()
        while true {
            if let info = entries[candidate] { return info }
            guard let dot = candidate.firstIndex(of: ".") else { return nil }
            candidate = String(candidate[candidate.index(after: dot)...])
        }
    }

    static func isApple(_ host: String) -> Bool {
        let h = host.lowercased()
        for suffix in appleSuffixes {
            if h == suffix || h.hasSuffix("." + suffix) { return true }
        }
        return false
    }

    /// В публичной версии определение «своих серверов приложения» не реализовано.
    static func isFirstParty(bundleID: String, domain: String, tracker: TrackerInfo) -> Bool {
        return false
    }

    private static let appleSuffixes: [String] = ["apple.com", "icloud.com"]

    private static let entries: [String: TrackerInfo] = [
        "google-analytics.com": TrackerInfo(owner: "Google", kind: .analytics),
        "app-measurement.com": TrackerInfo(owner: "Google (Firebase)", kind: .analytics),
        "doubleclick.net": TrackerInfo(owner: "Google", kind: .advertising),
        "facebook.com": TrackerInfo(owner: "Facebook (Meta)", kind: .social),
        "applovin.com": TrackerInfo(owner: "AppLovin", kind: .advertising),
        "unityads.unity3d.com": TrackerInfo(owner: "Unity Ads", kind: .advertising),
        "ironsrc.com": TrackerInfo(owner: "ironSource", kind: .advertising),
        "criteo.com": TrackerInfo(owner: "Criteo", kind: .advertising),
        "appsflyer.com": TrackerInfo(owner: "AppsFlyer", kind: .attribution),
        "adjust.com": TrackerInfo(owner: "Adjust", kind: .attribution),
        "xmode.io": TrackerInfo(owner: "X-Mode / Outlogic", kind: .dataBroker),
        "threatmetrix.com": TrackerInfo(owner: "LexisNexis ThreatMetrix", kind: .fingerprinting)
    ]
}
