import CoreGraphics

public class Vertex {

    public init(x: Double, y: Double, id: Int) {
        self.x = x
        self.y = y
        self.identifier = id
    }

    public func pointValue() -> CGPoint {
        return CGPoint(x: x, y: y)
    }

    public let x: Double
    public let y: Double
    // Идентификатор точки. От 0 до 67. Всего 68 значений для dlib. Либо 65 для vision
    public let identifier: Int

}

extension Vertex: Equatable {
    static public func ==(lhs: Vertex, rhs: Vertex) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()

        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }

        return result
    }
}

extension Vertex: Hashable {
    public var hashValue: Int {
        var seed = UInt(0)
        hash_combine(seed: &seed, value: UInt(bitPattern: x.hashValue))
        hash_combine(seed: &seed, value: UInt(bitPattern: y.hashValue))
        return Int(bitPattern: seed)
    }
}
