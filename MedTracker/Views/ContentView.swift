//
//  ContentView.swift
//  MedTracker
//
//  Main content view for the MedTracker app
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "pills.fill")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 60))
                    .padding()

                Text("MedTracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your medicine companion for international travel")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("MedTracker")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
