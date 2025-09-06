import SwiftUI

struct EmojiPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    private let emojis: [String] = [
        "📍","🏠","🏢","🏫","🏛️","🏖️","🏝️","🏔️","⛺️","🏕️","🗽","🗼","🕌","⛩️","⛲️",
        "🎢","🎡","🎠","🏟️","⚽️","🏀","🎾","🏊‍♂️","🏋️‍♀️",
        "🚗","🚲","🛴","🚌","🚆","🚇","✈️","🚢","⛴️","⛵️","🛥️","🚁",
        "🍽️","☕️","🍺","🍣","🍜","🍕","🥐","🥗","🛒","🏥","🏬","🏪","🏨"
    ]

    private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 12), count: 6) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(emojis, id: \.self) { e in
                        Button {
                            selection = e
                            dismiss()
                        } label: {
                            Text(e)
                                .font(.system(size: 28))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.secondary.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } }
            }
        }
    }
}

