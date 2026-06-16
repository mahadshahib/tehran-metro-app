import SwiftUI
import MetroDomain

/// The signature custom-drawn metro diagram: line-colored strokes, emphasized
/// interchange nodes, pan + zoom, and tap-to-detail. Geography stays fixed in
/// RTL (only surrounding chrome mirrors), per §12.3.
struct SchematicMapView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selected: StationID? = nil

    private let inset: CGFloat = 32

    private var layout: SchematicLayout { SchematicLayout(network: model.network) }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let size = geo.size
                Canvas { context, _ in
                    draw(in: &context, size: size)
                }
                .background(Color(.systemBackground))
                .contentShape(Rectangle())
                .gesture(magnification)
                .gesture(drag)
                .onTapGesture { location in
                    if let id = layout.nearestStation(to: location, in: size, scale: scale, offset: offset, inset: inset) {
                        selected = id
                    }
                }
                .environment(\.layoutDirection, .leftToRight)  // map geography never flips
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(Loc.tabMap.string(for: settings.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring) { scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero }
                    } label: { Image(systemName: "arrow.counterclockwise") }
                    .accessibilityLabel("Reset view")
                }
            }
            .sheet(item: Binding(get: { selected.map(IdentifiedID.init) }, set: { selected = $0?.id })) { wrapped in
                NavigationStack { StationDetailView(stationID: wrapped.id) }
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        // Strokes per line.
        for poly in layout.polylines {
            var path = Path()
            var started = false
            for stationID in poly.points {
                guard let p = layout.point(stationID, in: size, scale: scale, offset: offset, inset: inset) else { continue }
                if started { path.addLine(to: p) } else { path.move(to: p); started = true }
            }
            context.stroke(path, with: .color(Color(hex: poly.colorHex)),
                           style: StrokeStyle(lineWidth: 4 * min(scale, 2), lineCap: .round, lineJoin: .round))
        }
        // Station nodes.
        for station in model.network.stations.values {
            guard let p = layout.point(station.id, in: size, scale: scale, offset: offset, inset: inset) else { continue }
            let isInterchange = station.isInterchange
            let r: CGFloat = (isInterchange ? 6 : 3.5) * min(max(scale, 0.8), 2.2)
            let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
            if isInterchange {
                context.fill(Path(ellipseIn: rect), with: .color(Color(.systemBackground)))
                context.stroke(Path(ellipseIn: rect), with: .color(.primary), lineWidth: 2)
            } else {
                let color = station.lines.first.flatMap { model.line($0)?.colorHex }.map { Color(hex: $0) } ?? .gray
                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
    }

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in scale = min(max(lastScale * value, 0.6), 4) }
            .onEnded { _ in lastScale = scale }
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in lastOffset = offset }
    }
}

/// Wrapper so a `StationID` String can drive a `sheet(item:)`.
private struct IdentifiedID: Identifiable { let id: StationID }
