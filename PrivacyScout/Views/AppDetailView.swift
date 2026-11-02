import SwiftUI

struct AppDetailView: View {
    let report: AppReport

    var body: some View {
        List {
            headerSection
            findingsSection
            sensorsSection
            domainsSection
            recommendationsSection
            disclaimerSection
        }
        .navigationTitle(report.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Секции

    private var headerSection: some View {
        Section {
            HStack(spacing: 16) {
                ScoreRing(score: report.score, level: report.level, size: 72)
                VStack(alignment: .leading, spacing: 6) {
                    LevelBadge(level: report.level)
                    Text("Оценка риска \(report.score) из 100")
                        .font(.subheadline)
                    Text(report.bundleID)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var findingsSection: some View {
        Section("Что мы заметили") {
            ForEach(report.findings) { finding in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: finding.severity.icon)
                        .foregroundStyle(finding.severity.color)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(finding.title)
                            .font(.subheadline.weight(.semibold))
                        Text(finding.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private var sensorsSection: some View {
        if !report.usedSensors.isEmpty {
            Section("Доступ к данным и датчикам") {
                ForEach(report.usedSensors) { sensor in
                    HStack {
                        Label(sensor.title, systemImage: sensor.icon)
                        Spacer()
                        Text("\(report.sensors[sensor] ?? 0) раз")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var domainsSection: some View {
        if !report.domains.isEmpty {
            Section("С кем связывалось приложение") {
                ForEach(report.domains) { contact in
                    DomainRow(contact: contact)
                }
            }
        }
    }

    private var recommendationsSection: some View {
        Section("Что можно сделать") {
            ForEach(Analyzer.recommendations(for: report), id: \.self) { tip in
                Label {
                    Text(tip)
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    private var disclaimerSection: some View {
        Section {
            Text("Оценка построена на журнале iOS и встроенной базе известных трекеров. Это показатель риска, а не доказательство слежки: обращение к рекламному серверу не означает, что передавались именно ваши личные данные.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Строка домена

private struct DomainRow: View {
    let contact: DomainContact

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: contact.tracker?.kind.icon ?? "network")
                .foregroundStyle(contact.tracker != nil ? Color.orange : Color.secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(contact.domain)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if let tracker = contact.tracker {
                    Text("\(tracker.kind.title) · \(tracker.owner)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if let owner = contact.owner {
                    Text(owner)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("×\(contact.hits)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
