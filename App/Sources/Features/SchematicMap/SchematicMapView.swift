import SwiftUI
import MetroDomain

/// A custom-drawn 2D metro map: line-colored tracks, outlined station nodes,
/// emphasized interchanges, station labels, smooth pan/zoom, and tap-to-detail.
/// Fully offline. Geography never mirrors in RTL — only the chrome does.
struct SchematicMapView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings

    @State private var zoom: CGFloat = 1
    @State private var lastZoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var lastPan: CGSize = .zero
    @State private var selected: StationID?

    private let padding: CGFloat = 44
    private var layout: SchematicLayout { SchematicLayout(network: model.network) }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let size = geo.size
                ZStack(alignment: .bottom) {
                    Canvas { ctx, _ in draw(&ctx, size: size) }
                        .background(mapBackground)
                        .contentShape(Rectangle())
                        .gesture(magnification)
                        .simultaneousGesture(drag)
                        .onTapGesture(count: 2) { location in zoomIn(at: location, size: size) }
                        .onTapGesture { location in
                            if let id = layout.nearestStation(to: location, in: size, zoom: zoom, pan: pan, padding: padding) {
                                Haptics.selection()
                                selected = id
                            }
                        }
                        .environment(\.layoutDirection, .leftToRight)
                    legend
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(Loc.tabMap.string(for: settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(duration: 0.35)) { resetView() }
                    } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }
                    .accessibilityLabel(Loc.recenter.string(for: settings.language))
                }
            }
            .sheet(item: Binding(get: { selected.map(Wrapped.init) }, set: { selected = $0?.id })) { w in
                NavigationStack { StationDetailView(stationID: w.id) }
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var mapBackground: some View {
        LinearGradient(colors: [Color(.secondarySystemBackground), Color(.systemBackground)],
                       startPoint: .top, endPoint: .bottom)
    }

    // MARK: - Drawing

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        let lineWidth = min(max(4.5 * zoom, 3), 10)

        // 1) Line tracks.
        for poly in layout.polylines {
            var path = Path()
            var started = false
            for id in poly.points {
                guard let p = layout.screenPoint(id, in: size, zoom: zoom, pan: pan, padding: padding) else { continue }
                if started { path.addLine(to: p) } else { path.move(to: p); started = true }
            }
            ctx.stroke(path, with: .color(Color(hex: poly.colorHex)),
                       style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }

        // 2) Station nodes.
        for station in model.network.stations.values {
            guard let p = layout.screenPoint(station.id, in: size, zoom: zoom, pan: pan, padding: padding) else { continue }
            let interchange = station.isInterchange
            let r: CGFloat = interchange ? min(max(5 * zoom, 4.5), 9) : min(max(3 * zoom, 2.5), 6)
            let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
            let color = station.lines.first.flatMap { model.line($0)?.colorHex }.map { Color(hex: $0) } ?? .gray
            // White core for contrast, colored (or dark) ring.
            ctx.fill(Path(ellipseIn: rect), with: .color(Color(.systemBackground)))
            ctx.stroke(Path(ellipseIn: rect),
                       with: .color(interchange ? .primary : color),
                       lineWidth: interchange ? 3 : 2.2)
        }

        // 3) Labels — interchanges + terminals always; others when zoomed in.
        let showAll = zoom >= 2.2
        let terminals = Set(model.network.sortedLines.flatMap(\.terminals))
        for station in model.network.stations.values {
            let important = station.isInterchange || terminals.contains(station.id)
            guard showAll || important else { continue }
            guard let p = layout.screenPoint(station.id, in: size, zoom: zoom, pan: pan, padding: padding) else { continue }
            guard p.x > -40, p.x < size.width + 40, p.y > 0, p.y < size.height else { continue }
            drawLabel(&ctx, text: settings.stationName(station), at: p,
                      emphasized: station.isInterchange)
        }
    }

    private func drawLabel(_ ctx: inout GraphicsContext, text: String, at point: CGPoint, emphasized: Bool) {
        let resolved = ctx.resolve(
            Text(text).font(.app(size: emphasized ? 11 : 10, weight: emphasized ? .semibold : .regular))
        )
        let textSize = resolved.measure(in: CGSize(width: 200, height: 40))
        let anchor = CGPoint(x: point.x + 9, y: point.y)
        let pill = CGRect(x: anchor.x - 4, y: anchor.y - textSize.height / 2 - 2,
                          width: textSize.width + 8, height: textSize.height + 4)
        ctx.fill(Path(roundedRect: pill, cornerRadius: 4),
                 with: .color(Color(.systemBackground).opacity(0.7)))
        ctx.draw(resolved, at: CGPoint(x: anchor.x, y: anchor.y), anchor: .leading)
    }

    // MARK: - Legend

    private var legend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.s) {
                ForEach(model.network.sortedLines) { line in
                    HStack(spacing: DS.Spacing.xs) {
                        Circle().fill(Color(hex: line.colorHex)).frame(width: 10, height: 10)
                        Text(Loc.lineName(line.id, language: settings.language))
                            .font(.app(.caption2, weight: .medium))
                    }
                    .padding(.horizontal, DS.Spacing.s)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                }
            }
            .padding(.horizontal, DS.Spacing.l)
            .padding(.bottom, DS.Spacing.m)
        }
    }

    // MARK: - Gestures

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in zoom = min(max(lastZoom * value, 0.8), 6) }
            .onEnded { _ in lastZoom = zoom }
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                pan = CGSize(width: lastPan.width + value.translation.width,
                             height: lastPan.height + value.translation.height)
            }
            .onEnded { _ in lastPan = pan }
    }

    private func zoomIn(at location: CGPoint, size: CGSize) {
        withAnimation(.spring(duration: 0.3)) {
            if zoom > 1.5 {
                resetView()
            } else {
                zoom = 2.6; lastZoom = 2.6
                // Re-center the tapped point toward the middle.
                pan = CGSize(width: (size.width / 2 - location.x) * 1.2,
                             height: (size.height / 2 - location.y) * 1.2)
                lastPan = pan
            }
        }
    }

    private func resetView() {
        zoom = 1; lastZoom = 1; pan = .zero; lastPan = .zero
    }

    private struct Wrapped: Identifiable { let id: StationID }
}
