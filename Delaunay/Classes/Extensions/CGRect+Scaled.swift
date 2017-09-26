public extension CGRect {

    public func scaled(to size: CGSize) -> CGRect {
        return CGRect(x: self.origin.x * size.width,
                      y: self.origin.y * size.height,
                      width: self.size.width * size.width,
                      height: self.size.height * size.height)
    }

}
