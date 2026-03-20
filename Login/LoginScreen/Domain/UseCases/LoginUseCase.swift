//
//  LoginUseCase.swift
//  Login
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation

protocol LoginUseCase {
    func execute(username: String, password: String) async throws -> User
}

struct DefaultLoginUseCase: LoginUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(username: String, password: String) async throws -> User {
        try await repository.login(username: username, password: password)
    }
}


