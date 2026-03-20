import XCTest
@testable import Login


final class MockAuthRepository: AuthRepository {
    // Inputs captured for verification
    private(set) var receivedUsername: String?
    private(set) var receivedPassword: String?
    private(set) var callCount: Int = 0

    // Configurable outputs
    var result: Result<User, Error> = .failure(AuthError.serverError)
    var delayNanoseconds: UInt64 = 0 // Optional: simulate latency

    func login(username: String, password: String) async throws -> User {
        callCount += 1
        receivedUsername = username
        receivedPassword = password

        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        switch result {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Tests

final class DefaultLoginUseCaseTests: XCTestCase {

    func test_execute_returnsUserOnSuccess() async throws {
        // Arrange
        let expectedUser = User(id: UUID(), username: "rakesh")
        let mockRepo = MockAuthRepository()
        mockRepo.result = .success(expectedUser)
        let sut = DefaultLoginUseCase(repository: mockRepo)

        // Act
        let user = try await sut.execute(username: "rakesh", password: "secret")

        // Assert
        XCTAssertEqual(user, expectedUser, "Should return the user from repository")
        XCTAssertEqual(mockRepo.callCount, 1, "Repository should be called exactly once")
        XCTAssertEqual(mockRepo.receivedUsername, "rakesh")
        XCTAssertEqual(mockRepo.receivedPassword, "secret")
    }

    func test_execute_propagatesInvalidCredentialsError() async {
        // Arrange
        let mockRepo = MockAuthRepository()
        mockRepo.result = .failure(AuthError.invalidCredentials)
        let sut = DefaultLoginUseCase(repository: mockRepo)

        // Act
        do {
            _ = try await sut.execute(username: "", password: "")
            XCTFail("Expected to throw, but succeeded")
        } catch let error as AuthError {
            // Assert
            XCTAssertEqual(error, .invalidCredentials)
            XCTAssertEqual(mockRepo.callCount, 1)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_propagatesServerError() async {
        // Arrange
        let mockRepo = MockAuthRepository()
        mockRepo.result = .failure(AuthError.serverError)
        let sut = DefaultLoginUseCase(repository: mockRepo)

        // Act
        do {
            _ = try await sut.execute(username: "user", password: "pass")
            XCTFail("Expected to throw, but succeeded")
        } catch let error as AuthError {
            // Assert
            XCTAssertEqual(error, .serverError)
            XCTAssertEqual(mockRepo.callCount, 1)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_execute_forwardsParametersToRepository() async {
        // Arrange
        let mockRepo = MockAuthRepository()
        let expectedUser = User(id: UUID(), username: "paramCheck")
        mockRepo.result = .success(expectedUser)
        let sut = DefaultLoginUseCase(repository: mockRepo)

        // Act
        _ = try? await sut.execute(username: "paramCheck", password: "p@ss")

        // Assert
        XCTAssertEqual(mockRepo.receivedUsername, "paramCheck")
        XCTAssertEqual(mockRepo.receivedPassword, "p@ss")
    }

    func test_execute_supportsAsyncLatency() async throws {
        // Arrange
        let mockRepo = MockAuthRepository()
        mockRepo.delayNanoseconds = 100_000_000 // 0.1s
        let expectedUser = User(id: UUID(), username: "delayed")
        mockRepo.result = .success(expectedUser)
        let sut = DefaultLoginUseCase(repository: mockRepo)

        // Act
        let user = try await sut.execute(username: "delayed", password: "123")

        // Assert
        XCTAssertEqual(user, expectedUser)
        XCTAssertEqual(mockRepo.callCount, 1)
    }
}
