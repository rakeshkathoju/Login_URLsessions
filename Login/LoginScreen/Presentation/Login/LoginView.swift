//
//  LoginView.swift
//  LoginView
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome")
                .font(.largeTitle.bold())

            VStack(alignment: .leading, spacing: 12) {
                TextField("Username", text: $viewModel.username)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
            }

            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
            }

            Button(action: viewModel.login) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
        }
        .padding()
    }
}

#Preview {
    let repo = InMemoryAuthRepoImpl()
    let useCase = DefaultLoginUseCase(repository: repo)
    return LoginView(viewModel: LoginViewModel(loginUseCase: useCase, onSuccess: { _ in }))
}
