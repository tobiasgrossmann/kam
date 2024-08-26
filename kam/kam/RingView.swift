import SwiftUI

struct HealthRingsView: View {
    var moveProgress: Double // Red ring
    var exerciseProgress: Double // Green ring
    var standProgress: Double // Blue ring
    var lineWidth: CGFloat = 10 // Reduced line width for smaller rings
    
    var body: some View {
        ZStack {
            RingView(progress: standProgress, color: Color(red: 0.0, green: 0.8, blue: 1.0), lineWidth: lineWidth) // Cyan color
                .frame(width: 85, height: 85) // Reduced size and increased spacing
            
            RingView(progress: exerciseProgress, color: Color(red: 0.4, green: 1.0, blue: 0.0), lineWidth: lineWidth) // Green color
                .frame(width: 65, height: 65) // Reduced size and increased spacing
            
            RingView(progress: moveProgress, color: Color(red: 1.0, green: 0.3, blue: 0.3), lineWidth: lineWidth) // Red color
                .frame(width: 45, height: 45) // Reduced size and increased spacing
        }
    }
}

struct RingView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HealthRingsView(moveProgress: 0.7, exerciseProgress: 0.8, standProgress: 0.9)
    }
}
