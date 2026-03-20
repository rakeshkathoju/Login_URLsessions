//
//  LoginViewModel.swift
//  LoginViewModel
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
    var username: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var error: String?

    private let loginUseCase: LoginUseCase
    private let onSuccess: (User) -> Void

    init(loginUseCase: LoginUseCase, onSuccess: @escaping (User) -> Void) {
        self.loginUseCase = loginUseCase
        self.onSuccess = onSuccess
    }

    func login() {
        guard !username.isEmpty, !password.isEmpty else {
            error = "Please enter username and password"
            return
        }
        error = nil
        isLoading = true
        Task { [username, password] in
            do {
                let user = try await loginUseCase.execute(username: username, password: password)
                onSuccess(user)
            } catch {
                self.error = (error as? LocalizedError)?.errorDescription ?? "Something went wrong"
            }
            isLoading = false
        }
    }
}

