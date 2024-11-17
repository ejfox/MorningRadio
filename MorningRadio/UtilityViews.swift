//
//  UtilityViews.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/16/24.
//

import SwiftUI


// MARK: - ErrorView
struct ErrorView: View {
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text("Something went wrong.")
                .font(.title3)
                .foregroundColor(.white)
            Button(action: retryAction) {
                Text("Retry")
                    .bold()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
            }
            Spacer()
        }
        .padding()
        .background(Color.black)
    }
}
