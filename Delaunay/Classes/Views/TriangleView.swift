import UIKit
import GameplayKit

public class TriangleView: UIView {

    public func recalculate(vertexes: [Vertex]) {
        DispatchQueue.main.async {
            self.calculateMask(vertices: vertexes)
        }
    }

    private func calculateMask(vertices: [Vertex]) {
        if let sublayers = layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }

        let triangles = Delaunay().triangulate(vertices)

        for triangle in triangles {
            let triangleLayer = CAShapeLayer()
            triangleLayer.path = triangle.toPath()
            triangleLayer.strokeColor = UIColor.yellow.cgColor
            triangleLayer.fillColor = UIColor.clear.cgColor
            triangleLayer.backgroundColor = UIColor.white.cgColor
            layer.addSublayer(triangleLayer)
        }
    }

}
