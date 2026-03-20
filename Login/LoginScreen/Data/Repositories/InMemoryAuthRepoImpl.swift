//
//  InMemoryAuthRepository.swift.swift
//  Login
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation

final class InMemoryAuthRepoImpl: AuthRepository {
    private var storedUser: User?
    var currentUser: User? { storedUser }

    // Existing in-memory login (simulated delay)
    func login(username: String, password: String) async throws -> User {
        try await Task.sleep(nanoseconds: 400_000_000) // simulate delay
        guard !username.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        let user = User(id: UUID(), username: username)
        storedUser = user
        return user
    }

    func loginWithURLSession(
        username: String,
        password: String,
        baseURL: URL = URL(string: "https://your-api.com")!
    ) async throws -> User {
        // Build endpoint: POST https://your-api.com/login
        let url = baseURL.appending(path: "login") // iOS 16+ (or use appendingPathComponent("login"))

        // Request
        let requestBody = LoginRequest(username: username, password: password)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        // Perform call
        let (data, response) = try await URLSession.shared.data(for: request)

        // Validate response
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.serverError
        }

        switch http.statusCode {
        case 200 ... 299:
            // Decode JSON into your User model
            guard let loginResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) else {
                throw AuthError.decodingError
            }
            let user = User(id: loginResponse.id, username: loginResponse.username)
            storedUser = user
            return user

        case 401:
            throw AuthError.invalidCredentials

        default:
            throw AuthError.serverError
        }
    }

    func logout() async {
        storedUser = nil
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case serverError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password."
        case .serverError:
            return "A server error occurred. Please try again."
        case .decodingError:
            return "Received unexpected response from server."
        }
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let id: UUID
    let username: String
}
