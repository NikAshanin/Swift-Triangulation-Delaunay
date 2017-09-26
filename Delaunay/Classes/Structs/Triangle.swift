import CoreGraphics

/// A simple struct representing 3 vertices
public class Triangle {

    public init(vertex1: Vertex, vertex2: Vertex, vertex3: Vertex) {
        self.vertex1 = vertex1
        self.vertex2 = vertex2
        self.vertex3 = vertex3
    }

    public var vertex1: Vertex
    public var vertex2: Vertex
    public var vertex3: Vertex

    public func v1() -> CGPoint {
        return vertex1.pointValue()
    }

    public func v2() -> CGPoint {
        return vertex2.pointValue()
    }

    public func v3() -> CGPoint {
        return vertex3.pointValue()
    }
}

public extension Triangle {

    public func toPath() -> CGPath {

        let path = CGMutablePath()
        let point1 = vertex1.pointValue()
        let point2 = vertex2.pointValue()
        let point3 = vertex3.pointValue()

        path.move(to: point1)
        path.addLine(to: point2)
        path.addLine(to: point3)
        path.addLine(to: point1)

        path.closeSubpath()

        return path
    }

}

