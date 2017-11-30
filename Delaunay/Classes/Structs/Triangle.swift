import CoreGraphics

/// A simple struct representing 3 vertices
public final class Triangle {

    public var vertex1: Vertex
    public var vertex2: Vertex
    public var vertex3: Vertex

    public init(vertex1: Vertex, vertex2: Vertex, vertex3: Vertex) {
        self.vertex1 = vertex1
        self.vertex2 = vertex2
        self.vertex3 = vertex3
    }

}

public extension Triangle {

    public func toPath() -> CGPath {

        let path = CGMutablePath()
        let point1 = vertex1.point
        let point2 = vertex2.point
        let point3 = vertex3.point

        path.move(to: point1)
        path.addLine(to: point2)
        path.addLine(to: point3)
        path.addLine(to: point1)

        path.closeSubpath()

        return path
    }

}

