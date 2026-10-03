import SwiftUI

struct DrawingCanvas: View {
    @State private var paths: [DrawingPath] = []
    @State private var currentPath: DrawingPath?
    @State private var pointerLocations: [CGPoint] = []
    @State private var pointerDown: Bool = false
    
    let lineWidth: CGFloat = 4.0
    let lineColor: Color = .blue
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                
                ForEach(paths) { path in
                    Path { pathPath in
                        pathPath.move(to: path.points[0])
                        for point in path.points.dropFirst() {
                            pathPath.addLine(to: point)
                        }
                    }
                    .stroke(lineColor, lineWidth: lineWidth)
                }
                
                if let currentPath = currentPath {
                    Path { pathPath in
                        if let first = currentPath.points.first {
                            pathPath.move(to: first)
                            for point in currentPath.points.dropFirst() {
                                pathPath.addLine(to: point)
                            }
                        }
                    }
                    .stroke(lineColor, lineWidth: lineWidth)
                }
                
                ForEach(pointerLocations.indices, id: \.self) { index in
                    if index < pointerLocations.count {
                        let location = pointerLocations[index]
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .position(location)
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let point = value.location
                        if currentPath == nil {
                            currentPath = DrawingPath(points: [point], color: lineColor, lineWidth: lineWidth)
                        } else {
                            currentPath?.points.append(point)
                        }
                        if pointerLocations.count <= 0 {
                            pointerLocations.append(point)
                        } else {
                            pointerLocations[0] = point
                        }
                    }
                    .onEnded { _ in
                        if let path = currentPath {
                            paths.append(path)
                        }
                        currentPath = nil
                        pointerLocations = []
                    }
            )
            .onChange(of: pointerLocations) { newLocations in
                if !newLocations.isEmpty && !pointerDown {
                    pointerDown = true
                }
            }
        }
    }
}

struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    let color: Color
    let lineWidth: CGFloat
}

struct DrawingCanvas_Previews: PreviewProvider {
    static var previews: some View {
        DrawingCanvas()
            .frame(width: 800, height: 600)
    }
}
