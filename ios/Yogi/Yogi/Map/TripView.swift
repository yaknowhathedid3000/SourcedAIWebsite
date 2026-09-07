import SwiftUI
import MapKit

/// The card that sits over the map: a stack of prints from the reels the places
/// came out of, the trip name, and what it adds up to.
struct TripCard: View {
    @Environment(AppState.self) private var app
    let trip: Trip

    private var count: Int { app.places(in: trip).count }

    var body: some View {
        HStack(spacing: 14) {
            prints
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.yogiDisplay(21, weight: .semibold))
                    .foregroundStyle(YogiColor.ink)
                    .lineLimit(1)
                Text(trip.spotsLabel(count: count))
                    .font(.yogiSans(14))
                    .foregroundStyle(YogiColor.muted)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(YogiColor.muted)
        }
        .padding(14)
        .background(YogiColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
    }

    /// Three tilted prints with the source app badged on the front one, which is
    /// the whole point: these places came out of videos.
    private var prints: some View {
        ZStack {
            ForEach(Array(trip.coverEmoji.prefix(3).enumerated()), id: \.offset) { i, emoji in
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(YogiColor.optionFill)
                    .frame(width: 46, height: 60)
                    .overlay(Text(emoji).font(.system(size: 22)))
                    .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.white, lineWidth: 3))
                    .rotationEffect(.degrees(Double(i - 1) * 9))
                    .offset(x: CGFloat(i - 1) * 9)
                    .zIndex(Double(i))
            }
        }
        .frame(width: 74, height: 64)
        .overlay(alignment: .bottomTrailing) {
            if let first = trip.sources.first {
                Text(first.emoji)
                    .font(.system(size: 13))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.white).shadow(color: .black.opacity(0.2), radius: 3, y: 1))
                    .offset(x: 4, y: 4)
            }
        }
    }
}

/// The trip opened up: the map framed on the destination, then every place in
/// the order it was saved.
struct TripDetailView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    let trip: Trip

    @State private var position: MapCameraPosition = .automatic
    @State private var selected: Save?

    private var places: [Save] { app.places(in: trip) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                map
                header
                ForEach(places) { s in
                    Button { selected = s } label: { TripPlaceRow(save: s) }
                        .buttonStyle(PressableButtonStyle())
                    Divider().padding(.leading, 108)
                }
            }
            .padding(.bottom, 110)
        }
        .background(YogiColor.ground)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selected) { s in PlaceSheet(saveID: s.id) }
        .onAppear {
            position = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: trip.latitude, longitude: trip.longitude),
                span: MKCoordinateSpan(latitudeDelta: trip.spanDegrees, longitudeDelta: trip.spanDegrees)))
        }
    }

    private var map: some View {
        Map(position: $position) {
            ForEach(places) { s in
                if let p = s.place {
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude)) {
                        Button { selected = s } label: { PlacePin(save: s) }.buttonStyle(.plain)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(height: 320)
        .overlay(alignment: .topLeading) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(YogiColor.ink)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(YogiColor.card).shadow(color: .black.opacity(0.18), radius: 6, y: 2))
            }
            .padding(.leading, 16).padding(.top, 10)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(trip.name).font(.yogiDisplay(34)).foregroundStyle(YogiColor.ink)
            Text(trip.spotsLabel(count: places.count))
                .font(.yogiSans(16)).foregroundStyle(YogiColor.inkSecondary)
        }
        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 18)
    }
}

/// One place in the trip list: cover, name, what it is, and where it came from.
struct TripPlaceRow: View {
    let save: Save
    var body: some View {
        HStack(spacing: 14) {
            SaveCover(save: save, cornerRadius: 12).frame(width: 74, height: 74)
            VStack(alignment: .leading, spacing: 4) {
                Text(save.title).font(.yogiSans(17, weight: .semibold)).foregroundStyle(YogiColor.ink).lineLimit(1)
                Text([save.place?.category, save.place?.city].compactMap { $0 }.joined(separator: " · "))
                    .font(.yogiSans(15)).foregroundStyle(YogiColor.muted).lineLimit(1)
                HStack(spacing: 5) {
                    Text(save.sourcePlatform.emoji).font(.system(size: 11))
                    Text("Saved from \(save.sourcePlatform.title)")
                        .font(.yogiSans(13)).foregroundStyle(YogiColor.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
