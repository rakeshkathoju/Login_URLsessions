import XCTest
@testable import Login // <-- replace with your module name

final class InMemoryAuthRepositoryTests: XCTestCase {

    private var session: URLSession!
    private var sut: InMemoryAuthRepoImpl! // System Under Test
    private let baseURL = URL(string: "https://example.com")! // test base

    override func setUp() {
        super.setUp()
        session = makeMockedSession()
        sut = InMemoryAuthRepoImpl(session: session, baseURL: baseURL)
        MockURLProtocol.requestHandler = nil
    }

    override func tearDown() {
        sut = nil
        session = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - loginSleep

    func test_loginSleep_success_withNonEmptyCredentials_setsCurrentUserAndReturnsUser() async throws {
        let user = try await sut.loginSleep(username: "rakesh", password: "secret")
        XCTAssertEqual(user.username, "rakesh")
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.username, "rakesh")
    }

    func test_loginSleep_invalidCredentials_throwsInvalidCredentials() async {
        await assertThrows(AuthError.invalidCredentials) {
            _ = try await self.sut.loginSleep(username: "", password: "")
        }
    }

    // MARK: - login via URLSession

    func test_login_success_200_decodesAndStoresUser() async throws {
        // Arrange
        let expectedID = UUID()
        let expectedUsername = "rakesh"
        let body = LoginResponse(id: expectedID, username: expectedUsername)
        let responseData = try JSONEncoder().encode(body)

        MockURLProtocol.requestHandler = { request in
            // Verify request formation
            XCTAssertEqual(request.url, self.baseURL.appending(path: "login"))
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            // Verify encoded body
            if let httpBody = request.httpBody {
                let decoded = try JSONDecoder().decode(LoginRequest.self, from: httpBody)
                XCTAssertEqual(decoded.username, "rakesh")
                XCTAssertEqual(decoded.password, "secret")
            } else {
                XCTFail("Expected HTTP body")
            }

            let http = HTTPURLResponse(url: request.url!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!
            return (http, responseData)
        }

        // Act
        let user = try await sut.login(username: "rakesh", password: "secret")

        // Assert
        XCTAssertEqual(user.id, expectedID)
        XCTAssertEqual(user.username, expectedUsername)
        XCTAssertEqual(sut.currentUser?.id, expectedID)
        XCTAssertEqual(sut.currentUser?.username, expectedUsername)
    }

    func test_login_401_invalidCredentials_throwsInvalidCredentials() async {
        MockURLProtocol.requestHandler = { request in
            let http = HTTPURLResponse(url: request.url!,
                                       statusCode: 401,
                                       httpVersion: nil,
                                       headerFields: nil)!
            return (http, Data())
        }

        await assertThrows(AuthError.invalidCredentials) {
            _ = try await self.sut.login(username: "rakesh", password: "wrong")
        }
    }

    func test_login_non2xxNon401_throwsServerError() async {
        MockURLProtocol.requestHandler = { request in
            let http = HTTPURLResponse(url: request.url!,
                                       statusCode: 500,
                                       httpVersion: nil,
                                       headerFields: nil)!
            return (http, Data())
        }

        await assertThrows(AuthError.serverError) {
            _ = try await self.sut.login(username: "rakesh", password: "secret")
        }
    }

    func test_login_200_withInvalidJSON_throwsDecodingError() async {
        let invalidJSON = Data("{\"bad\":true}".utf8)

        MockURLProtocol.requestHandler = { request in
            let http = HTTPURLResponse(url: request.url!,
                                       statusCode: 200,
                                       httpVersion: nil,
                                       headerFields: nil)!
            return (http, invalidJSON)
        }

        await assertThrows(AuthError.decodingError) {
            _ = try await self.sut.login(username: "rakesh", password: "secret")
        }
    }

    // MARK: - logout

    func test_logout_clearsCurrentUser() async throws {
        // First set a user (either path works; use loginSleep for simplicity)
        _ = try await sut.loginSleep(username: "rakesh", password: "secret")
        XCTAssertNotNil(sut.currentUser)

        await sut.logout()
        XCTAssertNil(sut.currentUser)
    }
}

// MARK: - Helpers

extension XCTestCase {
    /// Helper to assert an async throwing block throws a specific error
    func assertThrows<E: Error & Equatable>(
        _ expectedError: E,
        file: StaticString = #file,
        line: UInt = #line,
        _ block: @escaping () async throws -> Void
    ) async {
        do {
            try await block()
            XCTFail("Expected to throw \(expectedError) but did not", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Threw unexpected error: \(error)", file: file, line: line)
        }
    }
}


// URLSession+Mock.swift (in test target)

import Foundation

func makeMockedSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

// MockURLProtocol.swift (in test target)

import Foundation

final class MockURLProtocol: URLProtocol {
    // Handler to define how to respond to requests
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler not set.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // No-op
    }
}
