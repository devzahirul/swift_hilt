import Foundation

@propertyWrapper
public struct Injected<T> {
    private let qualifier: Qualifier?
    private var value: T?

    public init(_ qualifier: Qualifier? = nil) {
        self.qualifier = qualifier
    }

    public var wrappedValue: T {
        mutating get {
            if let v = value { return v }
            let v: T = DI.shared.resolve(T.self, qualifier: qualifier)
            value = v
            return v
        }
        mutating set { value = newValue }
    }
}

