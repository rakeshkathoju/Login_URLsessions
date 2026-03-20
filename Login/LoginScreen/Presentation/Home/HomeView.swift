//
//  HomeView.swift
//  HomeView
//
//  Created by Rakesh Kumar Kathoju on 12/03/26.
//

import SwiftUI

struct HomeView: View {
    let user: User
    let onLogout: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Hello, \(user.username)!")
                    .font(.title)
                Button("Logout", action: onLogout)
                    .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView(user: User(id: UUID(), username: "Rakesh"), onLogout: {})
}

