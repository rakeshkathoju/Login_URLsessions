//
//  AuthRepository.swift
//  Login
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import Foundation

protocol AuthRepository {
    func login(username: String, password: String) async throws -> User
    func logout() async
    var currentUser: User? { get }
}
