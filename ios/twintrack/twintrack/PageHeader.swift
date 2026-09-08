import SwiftUI

/// Page content lets titles and subtitles grow naturally with Dynamic Type. Home
/// can include the approved mark without forcing it into the other tab headers.
struct PageHeader: View {
    let title: String
    let subtitle: String
    var showsMark = true
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))

        layout {
            if showsMark {
                Image("TwinTrackHeaderMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 68, height: 34)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(colorScheme == .dark
                        ? Color(red: 242 / 255, green: 244 / 255, blue: 247 / 255)
                        : Color(red: 15 / 255, green: 27 / 255, blue: 45 / 255))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("pageTitle.\(title)")
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(colorScheme == .dark
                        ? Color(red: 226 / 255, green: 235 / 255, blue: 250 / 255).opacity(0.5)
                        : Color(red: 90 / 255, green: 107 / 255, blue: 130 / 255))
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 18)
    }
}
