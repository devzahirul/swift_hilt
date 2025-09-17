import SwiftUI
import SwiftHilt

struct UsersListView: View {
    @StateObject private var vm = UsersListViewModel(getUsers: resolve())

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading { ProgressView() }
                else if let err = vm.error { Text(err).foregroundColor(.red) }
                else {
                    List(vm.users) { u in
                        VStack(alignment: .leading) {
                            Text(u.name).font(.headline)
                            Text(u.email).font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("All Users")
            .onAppear { vm.load() }
        }
    }
}

struct UsersListView_Previews: PreviewProvider {
    static var previews: some View { UsersListView() }
}

