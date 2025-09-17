import Foundation

#if canImport(UIKit)
import UIKit
import ObjectiveC

private var diAssociationKey: UInt8 = 0

public extension UIViewController {
    /// A DI container associated with this view controller. Falls back to parent's container.
    /// If neither is set, a fresh container is created (unconfigured) which will fail to resolve missing providers.
    var diContainer: Container {
        get {
            if let c = objc_getAssociatedObject(self, &diAssociationKey) as? Container {
                return c
            }
            if let parent = parent { return parent.diContainer }
            return Container()
        }
        set { objc_setAssociatedObject(self, &diAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// Creates and assigns a child container scoped to this view controller.
    func makeScopedContainer() -> Container {
        let child = diContainer.child()
        self.diContainer = child
        return child
    }
}

#endif
