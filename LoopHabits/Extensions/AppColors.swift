import SwiftUI

extension Color {
    // Full Loop Habit Tracker 21-color palette (matches Android app)
    static let loopPalette: [String] = [
        "#D32F2F", "#E53935", "#F44336", "#EF9A9A",  // reds
        "#F57C00", "#FB8C00", "#FF9800", "#FFCC02",  // oranges/yellow
        "#388E3C", "#43A047", "#4CAF50", "#A5D6A7",  // greens
        "#0288D1", "#039BE5", "#03A9F4", "#81D4FA",  // blues
        "#7B1FA2", "#8E24AA", "#9C27B0", "#CE93D8",  // purples
        "#5D4037"                                     // brown
    ]

    // Semantic background colors (used explicitly where .systemBackground etc. don't match Loop style)
    static let loopGreen = Color(hex: "#00897B")!
}
