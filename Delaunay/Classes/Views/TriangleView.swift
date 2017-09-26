import UIKit
import GameplayKit

public class TriangleView: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.recalculate),
            name: NSNotification.Name(rawValue: "vertex"),
            object: nil)
    }

    @objc func recalculate(notification: NSNotification){
        guard let userInfo = notification.userInfo as? [String: Any] else {
            return
        }

        if let array: Array<Vertex> = userInfo["vertex"] as? Array<Vertex> {
            DispatchQueue.main.async {
                self.calculateMask(vertices: array)
            }
        }
    }

    private func calculateMask(vertices: [Vertex]) {
        if let sublayers = self.layer.sublayers {
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
