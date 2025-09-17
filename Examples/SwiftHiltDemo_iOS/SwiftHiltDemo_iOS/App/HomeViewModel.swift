import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?

    private let getUser: GetUserUseCase
    init(getUser: GetUserUseCase) { self.getUser = getUser }

    func load(id: Int) {
        isLoading = true
        error = nil
        Task {
            do {
                let u = try await getUser(id)
                self.user = u
            } catch {
                self.error = (error as? URLError)?.localizedDescription ?? String(describing: error)
            }
            self.isLoading = false
        }
    }
}

