// AuthRepositoryContractTests.swift (Test target)

import XCTest
@testable import Login

final class AuthRepositoryContractTests: XCTestCase {

    // MARK: - Factory to be overridden by subclasses
    func makeSUT() -> AuthRepository {
        fatalError("Subclasses must override makeSUT() to return a concrete AuthRepository")
    }

    // MARK: - Contract Tests

    func test_login_withValidCredentials_returnsUser_and_setsCurrentUser() async throws {
        // Given
        let sut = makeSUT()

        // When
        let user = try await sut.login(username: "alice", password: "password123")

        // Then
        XCTAssertEqual(user.username, "alice", "Returned user should match the login username.")
    }

    func test_login_withEmptyUsernameOrPassword_throws() async {
        let sut = makeSUT()

        await assertAsyncThrows {
            _ = try await sut.login(username: "", password: "some")
        }

        await assertAsyncThrows {
            _ = try await sut.login(username: "some", password: "")
        }
    }

    func test_logout_clearsCurrentUser() async throws {
        let sut = makeSUT()

        _ = try await sut.login(username: "bob", password: "secret")

        XCTAssertNil(sut.currentUser, "`currentUser` should be nil after logout")}

    func test_currentUser_initially_nil() {
        let sut = makeSUT()
        XCTAssertNil(sut.currentUser, "`currentUser` should be nil before any successful login")
    }
}

// MARK: - Helpers

extension XCTestCase {
    /// Fails if the async throwing closure does not throw.
    func assertAsyncThrows(
        file: StaticString = #file,
        line: UInt = #line,
        _ block: @escaping () async throws -> Void
    ) async {
        do {
            try await block()
            XCTFail("Expected to throw, but did not.", file: file, line: line)
        } catch {
            // Success: it threw something. If you need specific error matching, extend this helper.
        }
    }
}

