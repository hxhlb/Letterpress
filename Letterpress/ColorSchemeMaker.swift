//
//  ColorSchemeMaker.swift
//  Letterpress
//
//  Created by Rachel on 9/6/2025.
//

import SwiftUI

struct ColorSchemeMaker: View {
    @StateObject var vm = HudManager.shared
    @State var isAlertPresented: Bool = false

    static let feedbackGenerator = UINotificationFeedbackGenerator()

    var body: some View {
        List {
            Section {
                Toggle(isOn: $vm.isAdaptiveColorEnabled) {
                    Text("Adaptive Color")
                }
            } header: {
                Text("General")
                    .textCase(.none)
            } footer: {
                Text("Enable adaptive color to automatically adjust colors based on the artwork of the now playing song.")
            }
            Section {
                ColorPicker("Color #1", selection: $vm.color1)
                ColorPicker("Color #2", selection: $vm.color2)
                ColorPicker("Color #3", selection: $vm.color3)
                ColorPicker("Color #4", selection: $vm.color4)
            } header: {
                Text("Select Colors")
                    .textCase(.none)
            }
            Section {
                Button(role: .destructive) {
                    isAlertPresented = true
                } label: {
                    Text("Reset Colors")
                }
            }
        }
        .navigationTitle("Colors")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Apply") {
                    vm.saveColors()
                    vm.reloadHud(notify: true)
                    Self.feedbackGenerator.notificationOccurred(.success)
                }
            }
        }
        .alert("Reset Colors", isPresented: $isAlertPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetColors()
            }
        } message: {
            Text("Are you sure you want to reset the colors?")
        }
        .onDisappear {
            vm.saveColors()
            vm.reloadHud(notify: true)
        }
    }

    func resetColors() {
        vm.color1 = .white
        vm.color2 = .clear
        vm.color3 = .clear
        vm.color4 = .clear
    }
}
