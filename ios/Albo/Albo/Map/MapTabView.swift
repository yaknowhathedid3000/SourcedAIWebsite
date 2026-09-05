import SwiftUI
import MapKit
import CoreLocation

/// Globe map with filters, search, places list and place sheet (Albo #133 to #144).
struct MapTabView: View {
    @Environment(AppState.self) private var app

    enum Filter: String, CaseIterable, Identifiable {
        case all, wantToGo, mine
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: return "Show all"
            case .wantToGo: return "Want to go"
            case .mine: return "Only my saves"
            }
        }
        var symbol: String {
            switch self {
            case .all: return "globe"
            case .wantToGo: return "megaphone"
            case .mine: return "bookmark.fill"
            }
        }
    }

    @State private var position: MapCameraPosition = .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 30, longitude: 5), distance: 22_000_000))
    @State private var filter: Filter = .all
    @State private var query = ""
    @State private var selected: Save? = nil
    @State private var showList = false
    @State private var showWarmup = false
    @State private var locationManager = CLLocationManager()

    private var places: [Save] {
        var pool = app.saves.filter { $0.place != nil }
        switch filter {
        case .all: break
        case .wantToGo: pool = pool.filter { $0.status == .wantTo }
        case .mine: pool = pool.filter { $0.savedBy.contains { $0.handle == app.me.handle } }
        }
        if !query.isEmpty {
            pool = pool.filter { $0.title.localizedCaseInsensitiveContains(query) || ($0.place?.city ?? "").localizedCaseInsensitiveContains(query) }
        }
        return pool
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                ForEach(places) { s in
                    if let p = s.place {
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)) {
                            Button { selected = s } label: { PlacePin(save: s) }.buttonStyle(.plain)
                        }
                    }
                }
                UserAnnotation()
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls { MapCompass() }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .bottom) {
                    Menu {
                        Button { showList = true } label: { Label("Search in collection...", systemImage: "square.stack") }
                        ForEach(Filter.allCases) { f in Button { filter = f } label: { Label(f.title, systemImage: f.symbol) } }
                    } label: {
                        HStack(spacing: 8) {
                            if filter != .all { Image(systemName: filter.symbol).font(.system(size: 16)) }
                            Text(filter.title).font(.alboSans(17, weight: .semibold))
                            Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(filter == .all ? AlboColor.ink : .white)
                        .padding(.horizontal, 18).frame(height: 50)
                        .background(filter == .all ? AlboColor.card : AlboColor.ink, in: Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    }
                    Spacer()
                    VStack(spacing: 14) {
                        FloatingButton(action: { showList = true }) { Image(systemName: "building.2").font(.system(size: 20)).foregroundStyle(AlboColor.ink) }
                            .accessibilityLabel("Places list")
                        FloatingButton(action: recenter) { Image(systemName: "location").font(.system(size: 20)).foregroundStyle(AlboColor.ink) }
                            .accessibilityLabel("My location")
                    }
                }
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass").font(.system(size: 22)).foregroundStyle(AlboColor.inkSecondary)
                    TextField("Search places...", text: $query).font(.alboSans(19))
                        .onSubmit { if let first = places.first, let p = first.place { withAnimation { position = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude), span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 8))) } } }
                    if !query.isEmpty { Button { query = "" } label: { Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundStyle(AlboColor.ink) } }
                }
                .padding(.horizontal, 22).frame(height: 64)
                .background(AlboColor.card, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            }
            .padding(.horizontal, 16).padding(.bottom, 12)
        }
        .sheet(item: $selected) { s in PlaceSheet(saveID: s.id) }
        .sheet(isPresented: $showList) { PlacesListSheet(query: query) { s in showList = false; selected = s } }
        .overlay { if showWarmup { LocationWarmup { showWarmup = false; app.hasSeenLocationWarmup = true; locationManager.requestWhenInUseAuthorization() } } }
        .onAppear { if !app.hasSeenLocationWarmup { showWarmup = true } }
    }

    private func recenter() {
        withAnimation { position = .userLocation(fallback: .camera(MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 14.6, longitude: 121.0), distance: 60_000))) }
    }
}

/// Flag or emoji in a white rounded tile with an uppercase caption (Albo #139, #144).
struct PlacePin: View {
    let save: Save
    var body: some View {
        VStack(spacing: 4) {
            Text(save.place?.countryFlag ?? save.place?.emoji ?? "📍").font(.system(size: 26))
                .padding(6).background(AlboColor.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(save.status == .wantTo ? AlboColor.systemBlue : AlboColor.hairline, lineWidth: 2))
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
            VStack(spacing: 0) {
                if save.status == .wantTo { Text("WANT TO GO").font(.system(size: 9, weight: .bold)).italic().tracking(0.5) }
                Text(save.title).font(.alboSans(13, weight: .bold))
            }
            .foregroundStyle(.white)
            .shadow(color: .black, radius: 2)
        }
    }
}

/// Frosted-glass permission warm-up over the dark globe (Albo #133).
struct LocationWarmup: View {
    let onContinue: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 18) {
                MascotView(variant: .explorer).frame(width: 110)
                Text(orphanSafe: "Enable Location for Better Experience").font(.alboSans(22, weight: .bold)).foregroundStyle(AlboColor.ink).multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 10) {
                    Text("We use your location to:").font(.alboSans(16, weight: .semibold)).foregroundStyle(AlboColor.ink)
                    ForEach(["Show places near you", "Calculate distances to saved locations", "Provide personalized recommendations"], id: \.self) { t in
                        HStack(spacing: 10) { Circle().fill(AlboColor.systemBlue).frame(width: 6, height: 6); Text(t).font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary) }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 10) {
                    Image(systemName: "shield.lefthalf.filled").font(.system(size: 18)).foregroundStyle(AlboColor.systemBlue)
                    Text("Your location data stays private and is never shared").font(.alboSans(14)).foregroundStyle(AlboColor.inkSecondary)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(AlboColor.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                PrimaryButton(title: "Continue", style: .blue, action: onContinue)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 24)
        }
    }
}

/// Places list sheet with a search pill and rows (Albo #136).
struct PlacesListSheet: View {
    @Environment(AppState.self) private var app
    @State var query: String
    let onSelect: (Save) -> Void

    private var results: [Save] {
        let pool = app.saves.filter { $0.place != nil } + SampleData.catalog.filter { $0.place != nil && !app.saves.contains($0) }
        guard !query.isEmpty else { return pool }
        return pool.filter { $0.title.localizedCaseInsensitiveContains(query) || ($0.place?.city ?? "").localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 14) {
            Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).padding(.top, 8)
            SearchPill(placeholder: "Search places", text: $query, leadingEmoji: "🗺️")
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { s in
                        Button { onSelect(s) } label: {
                            HStack(spacing: 14) {
                                SaveCover(save: s, cornerRadius: 12).frame(width: 96, height: 128)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(s.title).font(.alboSans(20, weight: .bold)).foregroundStyle(AlboColor.ink).lineLimit(1)
                                    Text(s.metaLine).font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary).lineLimit(1)
                                    HStack(spacing: 6) {
                                        AvatarStack(users: s.savedBy.isEmpty ? [SampleData.isaac, SampleData.jake] : s.savedBy, size: 22)
                                        Text("\(s.saveCount) saves").font(.alboSans(15)).foregroundStyle(AlboColor.inkSecondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "megaphone").font(.system(size: 18)).foregroundStyle(AlboColor.ink).frame(width: 52, height: 52).background(Circle().stroke(AlboColor.hairline, lineWidth: 1.5))
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

/// Place sheet from the map: serif title, flag, chips, hours, photos, saves (Albo #140).
struct PlaceSheet: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let saveID: UUID
    @State private var showActions = false
    @State private var showDetail = false

    var body: some View {
        if let s = app.save(saveID), let p = s.place {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Capsule().fill(AlboColor.hairline).frame(width: 40, height: 5).frame(maxWidth: .infinity).padding(.top, 8)
                    Text(s.title).alboText(.screenTitle)
                    if let flag = p.countryFlag { Text(flag).font(.system(size: 30)) }
                    HStack(spacing: 10) {
                        ActionChip(systemImage: "safari", title: "Directions") { openDirections(p) }
                        if let site = p.website { Link(destination: site) { HStack(spacing: 8) { Image(systemName: "link"); Text("Website").font(.alboSans(17, weight: .medium)) }.foregroundStyle(AlboColor.ink).padding(.horizontal, 18).frame(height: 52).background(AlboColor.optionFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous)) } }
                        ActionChip(systemImage: "ellipsis", title: "More") { showActions = true }
                    }
                    Text(p.hoursLabel ?? "No opening times found").font(.alboSans(18)).foregroundStyle(AlboColor.muted)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(p.photoEmoji.enumerated()), id: \.offset) { _, e in
                                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color(hex: s.coverTint)).frame(width: 190, height: 230).overlay(Text(e).font(.system(size: 60)))
                            }
                        }
                    }
                    HStack(spacing: 12) {
                        AvatarStack(users: s.savedBy)
                        Text("\(s.saveCount) saves").font(.alboSans(16)).foregroundStyle(AlboColor.inkSecondary)
                        ForEach(s.reactions) { r in
                            HStack(spacing: 6) { Text(r.emoji); Text("\(r.count)") }.font(.alboSans(15)).foregroundStyle(AlboColor.ink).padding(.horizontal, 12).frame(height: 36).background(AlboColor.optionFill, in: Capsule())
                        }
                        Spacer()
                        Button("Open") { showDetail = true }.font(.alboSans(16, weight: .semibold)).foregroundStyle(AlboColor.ink)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
            .sheet(isPresented: $showActions) { ItemActionsSheet(saveID: saveID) }
            .sheet(isPresented: $showDetail) { NavigationStack { SaveDetailView(saveID: saveID) } }
        }
    }

    private func openDirections(_ p: PlaceDetails) {
        let coordinate = CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)
        switch app.defaultMap {
        case .apple:
            let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
            item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
        case .google:
            if let url = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(p.latitude),\(p.longitude)") { UIApplication.shared.open(url) }
        }
    }
}
