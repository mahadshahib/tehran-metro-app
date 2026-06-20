import SwiftUI
import MetroDomain

/// A small, elegant first-launch walkthrough so new users aren't confused.
/// Presented full-screen; calls `onDone` when finished or skipped.
struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    let onDone: () -> Void

    @State private var index = 0
    private var lang: AppLanguage { settings.language }

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let tint: Color
        let title: LocalizedText
        let body: LocalizedText
    }

    private let pages: [Page] = [
        Page(symbol: "tram.fill", tint: Color(hex: "#E0001F"),
             title: Loc.onboardWelcomeTitle, body: Loc.onboardWelcomeBody),
        Page(symbol: "point.topleft.down.to.point.bottomright.curvepath.fill", tint: Color(hex: "#2F4389"),
             title: Loc.onboardPlanTitle, body: Loc.onboardPlanBody),
        Page(symbol: "map.fill", tint: Color(hex: "#007E46"),
             title: Loc.onboardExploreTitle, body: Loc.onboardExploreBody),
        Page(symbol: "wifi.slash", tint: Color(hex: "#EF639F"),
             title: Loc.onboardOfflineTitle, body: Loc.onboardOfflineBody)
    ]

    private var isLast: Bool { index >= pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(Loc.skip.string(for: lang)) { finish() }
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DS.Spacing.l)
            .padding(.top, DS.Spacing.m)

            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                    pageView(page).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut, value: index)

            Button {
                Haptics.tap()
                if isLast { finish() }
                else { withAnimation { index += 1 } }
            } label: {
                Text((isLast ? Loc.getStarted : Loc.next).string(for: lang))
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, DS.Spacing.l)
            .padding(.bottom, DS.Spacing.xl)
        }
        .background(Color(.systemBackground))
    }

    private func pageView(_ page: Page) -> some View {
        VStack(spacing: DS.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [page.tint, page.tint.opacity(0.6)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 132, height: 132)
                    .shadow(color: page.tint.opacity(0.4), radius: 18, y: 8)
                Image(systemName: page.symbol)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(spacing: DS.Spacing.m) {
                Text(page.title.string(for: lang))
                    .font(.app(.title, weight: .bold))
                    .multilineTextAlignment(.center)
                Text(page.body.string(for: lang))
                    .font(.app(.body))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
            }
        }
        .padding(.bottom, DS.Spacing.xxl)
    }

    private func finish() {
        Haptics.success()
        onDone()
    }
}
