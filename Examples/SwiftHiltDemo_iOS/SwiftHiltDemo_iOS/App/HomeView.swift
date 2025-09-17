import SwiftUI
import SwiftHilt

struct HomeView: View {
    @State private var idText = "1"
    @StateObject private var vm = HomeViewModel(getUser: resolve())

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    TextField("User ID", text: $idText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    Button("Load") { load() }
                        .buttonStyle(.borderedProminent)
                }

                if vm.isLoading { ProgressView() }
                if let err = vm.error { Text(err).foregroundColor(.red) }
                if let u = vm.user {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ID: \(u.id)")
                        Text("Name: \(u.name)")
                        Text("Email: \(u.email)")
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Users")
            .onAppear { load() }
        }
    }

    private func load() {
        let id = Int(idText) ?? 1
        vm.load(id: id)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View { HomeView() }
}

