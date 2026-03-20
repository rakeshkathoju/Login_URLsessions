# Building a Simple Login App in SwiftUI with Clean Architecture

Clean Architecture is a software design philosophy that separates the concerns of a software project into distinct layers. This separation makes the codebase easier to understand, maintain, and test. In this article, we'll walk through a simple SwiftUI login application built with Clean Architecture principles.

## Project Structure

Our project is divided into three main layers:

*   **Domain:** This is the core of our application. It contains the business logic and is independent of any other layer.
*   **Data:** This layer is responsible for providing data to the application, whether from a network service, a local database, or in-memory storage.
*   **Presentation:** This is the UI layer of the application. It's responsible for displaying data to the user and handling user interactions.

Here's a look at our project's file structure:

## Domain Layer

The Domain layer is the heart of our application. It contains the business rules and is completely independent of the UI, database, or any external framework.

### Entity

Entities are the core business objects of the application. In our case, we have a simple `User` entity.

**Login/LoginScreen/Domain/Entities/User.swift**
```swift
import Foundation

struct User: Equatable, Identifiable {
    let id: UUID
    let username: String
}
```

### Repository Protocol

The Domain layer defines repository protocols that act as a contract for the Data layer. These protocols define how the Domain layer interacts with the data source, but they don't know how the data is actually stored or retrieved.

**Login/LoginScreen/Domain/Repositories/AuthRepository.swift**
```swift
import Foundation

protocol AuthRepository {
    func login(username: String, password: String) async throws -> User
    func logout() async
    var currentUser: User? { get }
}
```

### Use Case

Use cases represent the specific actions a user can perform in the application. They orchestrate the flow of data between the UI and the repositories.

**Login/LoginScreen/Domain/UseCases/LoginUseCase.swift**
```swift
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
```

## Data Layer

The Data layer provides a concrete implementation of the repository protocols defined in the Domain layer. It's responsible for fetching data from a remote server, a local database, or any other data source.

In our example, we're using an in-memory repository for simplicity.

**Login/LoginScreen/Data/Repositories/InMemoryAuthRepoImpl.swift**
```swift
import Foundation

final class InMemoryAuthRepoImpl: AuthRepository {
    
    private var storedUser: User?
    var currentUser: User? { storedUser }

    func login(username: String, password: String) async throws -> User {
        try await Task.sleep(nanoseconds: 400_000_000) // simulate delay
        guard !username.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        let user = User(id: UUID(), username: username)
        storedUser = user
        return user
    }

    func logout() async {
        storedUser = nil
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password."
        }
    }
}
```

## Presentation Layer

The Presentation layer is responsible for displaying the UI and handling user interactions. We're using the Model-View-ViewModel (MVVM) pattern in this layer.

### ViewModel

The `LoginViewModel` is responsible for holding the state of the `LoginView` and handling the business logic for the login process. It communicates with the Domain layer through the `LoginUseCase`.

**Login/LoginScreen/Presentation/Login/LoginViewModel.swift**
```swift
import Foundation

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

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
```

### View

The `LoginView` is a SwiftUI view that observes the `LoginViewModel` and updates its UI based on the view model's state.

**Login/LoginScreen/Presentation/Login/LoginView.swift**
```swift
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
```

### Coordinator

The `AppCoordinator` is responsible for managing the navigation flow of the application. It decides which view to show based on the user's authentication status.

**Login/LoginScreen/Presentation/App/AppCoordinator.swift**
```swift
import SwiftUI
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

    func handleLoginSuccess(user: User) {.
        route = .home(user)
    }

    func logout() async {
        await authRepository.logout()
        route = .login
    }
}
```

## Conclusion

By structuring our application with Clean Architecture, we've created a codebase that is:

*   **Testable:** Each layer can be tested independently.
*   **Maintainable:** Changes in one layer have minimal impact on other layers.
*   **Flexible:** It's easy to swap out implementations, such as replacing the in-memory repository with a real network-based repository, without affecting the rest of the application.

This simple login app demonstrates the power of Clean Architecture in building robust and scalable SwiftUI applications.
