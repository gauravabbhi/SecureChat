//
//  RegistrationView.swift
//  ChatAppSwiftUI
//
//  Created by Gaurav Abbhi on 7/5/2024.
//

import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @StateObject private var nfcManager: NFCManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var isScanning = false
    @State private var nfcData: String?
    
    init() {
         let appState = AppState()
         _nfcManager = StateObject(wrappedValue: NFCManager(appState: appState))
     }
    
    var body: some View {
        VStack {
            Spacer()
            // logo image
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding()
            // textfields
            FloatingTextFieldsView(viewModel: viewModel)
            
            Button {
                           isScanning = true
                           nfcManager.scan()
                       } label: {
                           Text("Sign Up")
                               .font(.subheadline)
                               .fontWeight(.semibold)
                               .foregroundStyle(.white)
                               .frame(width: 360, height: 44)
                               .background(.green)
                               .clipShape(RoundedRectangle(cornerRadius: 10))
                       }
                       .padding(.vertical)
                       .alert(isPresented: $isScanning) {
                           Alert(
                               title: Text("NFC Scan"),
                               message: Text(nfcManager.message),
                               dismissButton: .default(Text("OK")) {
                                   isScanning = false
                                   if let nfcData = nfcManager.payload {
                                       self.nfcData = nfcData
                                       Task { try await viewModel.createUser() }
                                   }
                               }
                           )
                       }
            Spacer()
            Divider()
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Already have an account?")
                    Text("Sign in")
                        .fontWeight(.semibold)
                }
                .font(.footnote)
                .foregroundStyle(.gray)
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    RegistrationView()
}
