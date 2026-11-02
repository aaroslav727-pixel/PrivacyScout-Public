import Foundation

/// Вымышленные приложения для демонстрации. Реальные приложения здесь не упоминаются.
enum DemoData {

    static func parsed() -> ParsedReport {
        var p = ParsedReport()

        func sensor(_ bundle: String, _ category: SensorCategory, _ count: Int) {
            p.sensorCounts[bundle, default: [:]][category, default: 0] += count
        }
        func net(_ bundle: String, _ domain: String, _ hits: Int) {
            p.domainHits[bundle, default: [:]][domain, default: 0] += hits
        }

        // Фонарик, которому не нужна геолокация
        sensor("demo.torch", .location, 84)
        sensor("demo.torch", .contacts, 3)
        net("demo.torch", "graph.facebook.com", 40)
        net("demo.torch", "app-measurement.com", 25)
        net("demo.torch", "applovin.com", 60)
        net("demo.torch", "xmode.io", 12)
        net("demo.torch", "appsflyer.com", 8)

        // Погода: геолокация нужна, но трекеров много
        sensor("demo.weather", .location, 120)
        net("demo.weather", "doubleclick.net", 33)
        net("demo.weather", "app-measurement.com", 18)
        net("demo.weather", "criteo.com", 9)
        net("demo.weather", "api.demo-weather.example", 70)

        // Мессенджер: нужны микрофон и камера, трекеров мало
        sensor("demo.messenger", .microphone, 12)
        sensor("demo.messenger", .camera, 8)
        sensor("demo.messenger", .contacts, 2)
        net("demo.messenger", "app-measurement.com", 14)
        net("demo.messenger", "api.demo-messenger.example", 220)

        // Заметки: только iCloud
        net("demo.notes", "icloud.com", 30)

        // Игра: рекламных SDK очень много
        net("demo.game", "unityads.unity3d.com", 44)
        net("demo.game", "applovin.com", 51)
        net("demo.game", "ironsrc.com", 20)
        net("demo.game", "adjust.com", 6)
        net("demo.game", "appsflyer.com", 7)
        net("demo.game", "facebook.com", 15)
        net("demo.game", "criteo.com", 4)

        // Банк: антифрод-отпечаток и камера для фото чека
        sensor("demo.bank", .camera, 2)
        net("demo.bank", "threatmetrix.com", 5)
        net("demo.bank", "api.demo-bank.example", 80)

        // Системное приложение (по умолчанию скрыто)
        sensor("com.apple.camera", .camera, 30)
        sensor("com.apple.camera", .location, 10)
        net("com.apple.camera", "icloud.com", 12)

        let now = Date()
        p.lastDate = now
        p.firstDate = Calendar.current.date(byAdding: .day, value: -7, to: now)
        p.lineCount = 0
        return p
    }
}
