import SwiftUI
import CoreLocation

/// Shown as a sheet before opening Maps; displays the smart arrival buffer recommendation.
struct DepartureAdvisoryView: View {
  let destination: Destination
  let result: ArrivalBufferResult
  let onNavigate: () -> Void

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // ── Header ──────────────────────────────────────────────────────────
        VStack(spacing: 8) {
          Text(destination.icon)
            .font(.system(size: 48))
          Text(destination.name)
            .font(.title2.bold())
        }
        .padding(.top, 24)
        .padding(.bottom, 20)

        // ── Buffer card ──────────────────────────────────────────────────────
        VStack(spacing: 16) {
          BufferRow(
            symbol: result.eventType.symbol,
            title: "Event type",
            subtitle: result.eventType.label,
            value: "+\(result.baseBufferMinutes) min",
            color: .accentColor
          )

          Divider()

          BufferRow(
            symbol: result.trafficCondition.symbol,
            title: "Traffic",
            subtitle: result.trafficCondition.label,
            value: result.trafficCondition.additionalBufferMinutes > 0
              ? "+\(result.trafficCondition.additionalBufferMinutes) min"
              : "No extra",
            color: trafficColor
          )

          Divider()

          if result.estimatedTravelSeconds > 0 {
            BufferRow(
              symbol: "car.fill",
              title: "Travel time",
              subtitle: "MapKit estimate",
              value: result.formattedTravelTime,
              color: .secondary
            )
            Divider()
          }

          // Total
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text("Recommended buffer")
                .font(.subheadline.bold())
              Text("Arrive this early before your event")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(result.totalBufferMinutes) min")
              .font(.title3.bold())
              .foregroundStyle(.accentColor)
          }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)

        Spacer()

        // ── Actions ──────────────────────────────────────────────────────────
        VStack(spacing: 12) {
          Button {
            dismiss()
            onNavigate()
          } label: {
            Label("Open in Maps", systemImage: "map.fill")
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
              .background(Color.accentColor)
              .foregroundStyle(.white)
              .clipShape(RoundedRectangle(cornerRadius: 14))
              .font(.body.bold())
          }

          Button("Cancel", role: .cancel) { dismiss() }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
      }
      .background(Color(.systemGroupedBackground).ignoresSafeArea())
      .navigationTitle("Departure Advisory")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") { dismiss() }
        }
      }
    }
  }

  private var trafficColor: Color {
    switch result.trafficCondition {
    case .light:    return .green
    case .moderate: return .orange
    case .heavy:    return .red
    case .unknown:  return .secondary
    }
  }
}

// MARK: - BufferRow

private struct BufferRow: View {
  let symbol: String
  let title: String
  let subtitle: String
  let value: String
  let color: Color

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: symbol)
        .font(.system(size: 18))
        .foregroundStyle(color)
        .frame(width: 24)
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline)
        Text(subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Text(value)
        .font(.subheadline.bold())
        .foregroundStyle(.primary)
    }
  }
}
