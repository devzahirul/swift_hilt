import Foundation
import SwiftUI

@MainActor
final class UsersListViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var error: String?

    private let getUsers: GetUsersUseCase
    init(getUsers: GetUsersUseCase) { self.getUsers = getUsers }

    func load() {
        isLoading = true
        error = nil
        Task {
            do {
                self.users = try await getUsers()
            } catch {
                self.error = (error as? URLError)?.localizedDescription ?? String(describing: error)
            }
            self.isLoading = false
        }
    }
}

