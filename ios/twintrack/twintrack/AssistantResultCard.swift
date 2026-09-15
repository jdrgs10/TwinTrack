import SwiftUI

struct AssistantResultCard: View {
    let card: AssistantCard
    @Environment(\.colorScheme) private var colorScheme
    private var palette: AssistantPalette { AssistantPalette(colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(card.title).font(.headline).foregroundStyle(palette.accent)
            if let baseline = card.baseline { number("Baseline", baseline) }
            if let prediction = card.prediction {
                number(card.kind == .scenario ? "Scenario" : "Predicted assessment score", prediction)
            }
            if let delta = card.delta {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Predicted change").font(.caption)
                    Text(PredictionHistoryDisplay.delta(delta)).font(.title2.weight(.semibold)).monospacedDigit()
                }
            }
            Text(card.message).font(.footnote).foregroundStyle(.secondary)
            if !card.fields.isEmpty {
                DisclosureGroup("Inputs and source details") {
                    ForEach(Array(card.fields.enumerated()), id: \.offset) { _, field in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(field.label).font(.caption).foregroundStyle(.secondary)
                            Text(field.value).font(.subheadline).monospacedDigit()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
                    }
                }
                .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(palette.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(palette.accent.opacity(0.2)) }
        .privacySensitive()
        .accessibilityIdentifier("assistantResultCard.\(card.kind.rawValue)")
    }

    private func number(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased()).font(.caption.weight(.semibold))
            Text(HomeDisplay.prediction(value)).font(.largeTitle.weight(.semibold)).monospacedDigit()
        }
    }
}
