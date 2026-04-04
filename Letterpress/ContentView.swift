//
//  ContentView.swift
//  Letterpress
//
//  Created by Rachel on 8/6/2025.
//

import SwiftUI
import SwiftUIBackports

struct ContentView: View {
    @State var isSheetPresented: Bool = true

    var body: some View {
        DotGridView()
            .ignoresSafeArea()
            .statusBarHidden(true)
            .sheet(isPresented: $isSheetPresented) {
                content
            }
    }

    var content: some View {
        NavigationView {
            SheetView()
        }
        .interactiveDismissDisabled()
        .modify { body in
            if #available(iOS 16, *) {
                body.presentationDetents([.medium])
            } else {
                body.backport.presentationDetents([.medium])
            }
        }
    }
}
