import SwiftUI

extension View {
    func getColor(level: Int = 0) -> Color {
        var level = level
        let initialLevel = level
        
        if let color = colors[initialLevel] {
            return color
        }
        
        while level >= 10 {
            level = level - 10
        }
        
        let r = 255
        var g = level * 40 < 255 ? 152 : (level * 20).clamped(to: 0...255)
        var b = (level * 40).clamped(to: 0...255)
        
        if (g == 255 && b == 255) {
            g = (level * 30 - 255).clamped(to: 0...255)
            b = (level * 40 - 255).clamped(to: 0...255)
        }
        
        let color = Color.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
        
        colors[initialLevel] = color
        
        return color
    }
}

var colors = [Int: Color]()
