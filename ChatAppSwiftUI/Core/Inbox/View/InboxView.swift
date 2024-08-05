import SwiftUI

struct InboxView: View {
    @State private var showNewMessageView = false
    @StateObject private var viewModel = InboxViewModel()
    @StateObject private var nfcManager = NFCManager()
    @State private var selectedUser: User?
    @State private var showChat = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var user: User? {
        return viewModel.currentUser
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    ForEach(viewModel.latestMessages) { message in
                        ZStack {
                            NavigationLink(value: message) {
                                EmptyView()
                            }
                            .opacity(0)
                            InboxRowView(message: message)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .onChange(of: selectedUser, perform: { newValue in
                    showChat = newValue != nil
                })
                .navigationDestination(for: Message.self, destination: { message in
                    if let user = message.user {
                        ChatView(user: user)
                            .navigationBarBackButtonHidden()
                    }
                })
                .navigationDestination(for: Route.self, destination: { route in
                    switch route {
                    case .profile(let user):
                        ProfileView(user: user)
                            .navigationBarBackButtonHidden()
                    case .ChatView(let user):
                        ChatView(user: user)
                            .navigationBarBackButtonHidden()
                    }
                })
                .navigationDestination(isPresented: $showChat, destination: {
                    if let user = selectedUser {
                        ChatView(user: user)
                            .navigationBarBackButtonHidden()
                    }
                })
                .fullScreenCover(isPresented: $showNewMessageView) {
                    NewMessageView(selectedUser: $selectedUser)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.visible, for: .tabBar)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("SecureChat")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .navigationBarColor(Color(.darkGray))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 24) {
                            // Modified Button action to include completion handler
                            Button(action: {
                                nfcManager.onScanComplete = { scannedData in
                                    validateNFCData(scannedData: scannedData)
                                }
                                nfcManager.scan()
                            }) {
                                Image(systemName: "simcard")
                            }
                            
                            if let user {
                                NavigationLink(value: Route.profile(user)) {
                                    Image(systemName: "ellipsis")
                                }
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    }
                }
                
                Button {
                    showNewMessageView.toggle()
                    selectedUser = nil
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.darkGray))
                        .frame(width: 50, height: 50)
                        .padding()
                        .overlay {
                            Image(systemName: "plus.bubble.fill")
                                .foregroundStyle(.white)
                        }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("NFC Validation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func validateNFCData(scannedData: String?) {
        // Debugging: Print the scanned data
        if let scannedData = scannedData {
            print("Scanned Data: \(scannedData)")
        } else {
            print("Scanned Data: nil")
        }

        // Debugging: Print the selected user for debugging
        if let selectedUser = selectedUser {
            print("Selected User ID: \(selectedUser.id)")
        } else {
            print("Selected User: nil")
        }

        // Extract the name from the scanned data
        var extractedName: String? = nil
        if let scannedData = scannedData {
            let lines = scannedData.split(separator: "\n")
            for line in lines {
                if line.hasPrefix("Name:") {
                    let nameComponents = line.split(separator: ":")
                    if nameComponents.count > 1 {
                        extractedName = nameComponents[1].trimmingCharacters(in: .whitespaces)
                    }
                    break
                }
            }
        }

        // Debugging: Print the extracted name
        if let extractedName = extractedName {
            print("Extracted Name: \(extractedName)")
        } else {
            print("Extracted Name: nil")
        }

        // Compare the extracted name with the selected user's ID
        if let extractedName = extractedName, let selectedUser = user, extractedName == selectedUser.id {
            alertMessage = "User ID matches!"
        } else {
            alertMessage = "User ID does not match."
        }
        showAlert = true
    }

}

#Preview {
    InboxView()
}

extension View {
    func navigationBarColor(_ backgroundColor: Color) -> some View {
        self.modifier(NavigationBarColorModifier(backgroundColor: backgroundColor))
    }
}

struct NavigationBarColorModifier: ViewModifier {
    var backgroundColor: Color

    init(backgroundColor: Color) {
        self.backgroundColor = backgroundColor
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = UIColor(backgroundColor)
        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
    }
}
