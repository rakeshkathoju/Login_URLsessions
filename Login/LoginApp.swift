//
//  LoginApp.swift
//  Login
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import SwiftUI
import Observation

@main
struct LoginApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
    }
}

@Observable
final class AppRootState {
    var coordinator = AppCoordinator()
}

struct AppRootView: View {
    @State private var state = AppRootState()

    var body: some View {
        switch state.coordinator.route {
        case .login:
            LoginView(
                viewModel: LoginViewModel(
                    loginUseCase: state.coordinator.loginUseCase,
                    onSuccess: { user in
                        state.coordinator.handleLoginSuccess(user: user)
                    }
                )
            )

        case .home(let user):
            HomeView(user: user) {
                Task { await state.coordinator.logout() }
            }
        }
    }
}



