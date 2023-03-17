extension Dictionary {
    func combinedWith(_ other: [Key: Value]) -> [Key: Value] {
        var dict = self
        for (key, value) in other {
            dict[key] = value
        }
        return dict
    }
}
