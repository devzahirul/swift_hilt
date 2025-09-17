import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct DIContainerKey: EnvironmentKey {
    public static let defaultValue: Container = DI.shared
}

public extension EnvironmentValues {
    var diContainer: Container {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}

public extension View {
    func diContainer(_ container: Container) -> some View {
        environment(\.diContainer, container)
    }
}

@propertyWrapper
public struct EnvironmentInjected<T>: DynamicProperty {
    @Environment(\.diContainer) private var container: Container
    private let qualifier: Qualifier?

    public init(_ qualifier: Qualifier? = nil) { self.qualifier = qualifier }

    public var wrappedValue: T {
        container.resolve(T.self, qualifier: qualifier)
    }
}

#endif
