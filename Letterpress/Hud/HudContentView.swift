//
//  HudContentView.swift
//  Letterpress
//
//  Created by Lessica on 6/8/25.
//

import SwiftUI

struct HudContentView: View {
    @StateObject var vm = HudViewModel.shared
    @State var isPresented: Bool = false

    var body: some View {
        ZStack {
            if vm.isActivated {
                HudFirefliesView()
            }
        }
        .ignoresSafeArea()
        .opacity(vm.isActivated && isPresented ? 1.0 : 0.0)
        .animation(.easeIn(duration: 0.5), value: combines(
            isPresented,
            vm.isActivated
        ))
        .onAppear {
            isPresented = true
        }
    }
}
