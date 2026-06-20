import SwiftUI
import UIKit
import MetroDomain

/// A CheetahTeam app promoted in Settings. Tapping "Get" opens its deep link in
/// the SibApp store.
struct PromoApp: Identifiable {
    let id: String
    let name: LocalizedText
    let tagline: LocalizedText
    let assetName: String        // image set name in the asset catalog
    let fallbackSymbol: String   // SF Symbol shown until the real logo is added
    let tint: Color
    let deepLink: URL?
}

enum CheetahPromo {
    /// Build a `sibappnew://application?id=…` deep link, percent-encoding the id
    /// (the Cheetah id contains Persian characters).
    static func deepLink(id: String) -> URL? {
        var components = URLComponents()
        components.scheme = "sibappnew"
        components.host = "application"
        components.queryItems = [URLQueryItem(name: "id", value: id)]
        return components.url
    }

    static let muvi = PromoApp(
        id: "muvi",
        name: Loc.muviName, tagline: Loc.muviTagline,
        assetName: "MuviLogo", fallbackSymbol: "play.rectangle.fill",
        tint: Color(red: 0.90, green: 0.05, blue: 0.09),
        deepLink: deepLink(id: "Muvi")
    )

    static let cheetah = PromoApp(
        id: "cheetah",
        name: Loc.cheetahName, tagline: Loc.cheetahTagline,
        assetName: "CheetahLogo", fallbackSymbol: "arrow.down.circle.fill",
        tint: Color(red: 1.0, green: 0.48, blue: 0.0),
        deepLink: deepLink(id: "دانلود-منیجر-چیتا-cheetah")
    )

    static let apps = [muvi, cheetah]

    static func open(_ app: PromoApp) {
        guard let url = app.deepLink else { return }
        UIApplication.shared.open(url)
    }
}

/// Renders an app's logo from the asset catalog, falling back to an elegant
/// gradient tile with an SF Symbol when the real logo hasn't been added yet.
struct AppLogoView: View {
    let assetName: String
    let fallbackSymbol: String
    let tint: Color
    var size: CGFloat = 46

    var body: some View {
        Group {
            if let uiImage = UIImage(named: assetName) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [tint, tint.opacity(0.65)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(
                        Image(systemName: fallbackSymbol)
                            .font(.system(size: size * 0.42, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 0.5)
        )
    }
}

/// The "More from CheetahTeam" Settings section.
struct CheetahPromoSection: View {
    @Environment(AppSettings.self) private var settings
    private var lang: AppLanguage { settings.language }

    var body: some View {
        Section {
            ForEach(CheetahPromo.apps) { app in
                PromoRow(app: app)
            }
        } header: {
            SectionHeaderLabel(Loc.moreFromCheetah.string(for: lang))
        } footer: {
            Text(Loc.madeByCheetah.string(for: lang))
                .font(.app(.footnote)).foregroundStyle(.secondary)
        }
    }
}

private struct PromoRow: View {
    @Environment(AppSettings.self) private var settings
    let app: PromoApp
    private var lang: AppLanguage { settings.language }

    var body: some View {
        HStack(spacing: DS.Spacing.m) {
            AppLogoView(assetName: app.assetName, fallbackSymbol: app.fallbackSymbol, tint: app.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name.string(for: lang)).font(.app(.body, weight: .medium))
                Text(app.tagline.string(for: lang))
                    .font(.app(.caption)).foregroundStyle(.secondary).lineLimit(2)
            }
            Spacer(minLength: DS.Spacing.s)
            Button {
                Haptics.tap()
                CheetahPromo.open(app)
            } label: {
                Label(Loc.getApp.string(for: lang), systemImage: "arrow.down.app.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(app.tint)
            .controlSize(.small)
        }
        .padding(.vertical, DS.Spacing.xs)
    }
}
