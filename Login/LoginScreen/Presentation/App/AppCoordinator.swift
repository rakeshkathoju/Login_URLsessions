//
//  AppCoordinator.swift
//  Login
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppCoordinator {
    enum Route: Equatable {
        case login
        case home(User)
    }

    var route: Route

    private let authRepository: AuthRepository
    let loginUseCase: LoginUseCase

    init() {
        let repository = InMemoryAuthRepoImpl()
        self.authRepository = repository
        self.loginUseCase = DefaultLoginUseCase(repository: repository)

        if let user = repository.currentUser {
            self.route = .home(user)
        } else {
            self.route = .login
        }
    }

    func handleLoginSuccess(user: User) {
        route = .home(user)
    }

    func logout() async {
        await authRepository.logout()
        route = .login
    }
}



