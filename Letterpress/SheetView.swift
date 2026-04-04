//
//  SheetView.swift
//  Letterpress
//
//  Created by Rachel on 11/6/2025.
//

import SwiftUI

struct SheetView: View {
    @StateObject var vm = HudManager.shared
    @State var isAlertPresented: Bool = false
    @State var latestVersionString: String?

    private static let isAbove16: Bool = {
        if #available(iOS 16, *) {
            return true
        } else {
            return false
        }
    }()

    var body: some View {
        List {
            if !Self.isAbove16 || latestVersionString != nil {
                upgradeSection
            }

            generalSection

            tokenizerModeSection
            fontSection
            opacitySection
            yOffsetSection

            particleBirthRateSection
            particleRangeSection
            particleSizeSection
            yParticleSlideSection
            particleLifespanSection
            particleSpeedSection
            particleSpeedVariationSection
            particleBurstCountSection
            particleBurstCountVariationSection
            particleAttractionStrengthSection
            particleDampingFactorSection
            particleInitialMultiplierSection
            particleFinalMultiplierSection

            labelSection
            labelFontSizeSection
            yLabelOffsetSection

            resetSection
        }
        .navigationTitle("Letterpress")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: ColorSchemeMaker()) {
                    Text("Colors")
                }
            }
        }
        .onAppear {
            CheckUpdateManager.shared.checkUpdateIfNeeded { latestVersion, _ in
                DispatchQueue.main.async {
                    withAnimation {
                        latestVersionString = latestVersion?.tagName
                    }
                }
            }
        }
        .alert("Reset to Defaults", isPresented: $isAlertPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                vm.resetDefaults()
                vm.reloadHud(notify: true)
            }
        } message: {
            Text("Are you sure you want to reset all settings to their defaults?")
        }
    }

    var upgradeSection: some View {
        Section {}
        footer: {
            VStack(alignment: .leading, spacing: 8) {
                if let latestVersionString {
                    Button {
                        CheckUpdateManager.shared.executeUpgrade()
                    } label: {
                        Text("New version \(latestVersionString) available!")
                    }
                }
                if !Self.isAbove16 {
                    Text("This app is designed for iOS 16 and later. Some features may not work perfectly on earlier versions.")
                }
            }
            .textCase(.none)
        }
        .transition(.opacity)
    }

    var generalSection: some View {
        Section {
            Toggle(isOn: $vm.isEnabled) {
                Text("Enable Letterpress")
            }
            Toggle(isOn: $vm.shouldDisplayOnLockScreen) {
                Text("Enable on Lock Screen")
            }
            Toggle(isOn: $vm.shouldDisplayWhenScreencast) {
                Text("Enable in Screenshots")
            }
            NavigationLink(destination: AppPicker().ignoresSafeArea()) {
                Text("Selected Applications")
            }
        } header: {
            Text("General")
                .textCase(.none)
        } footer: {
            Text("Enable particle effects based on lyrics when these specific applications are playing music.")
                .textCase(.none)
        }
    }

    var tokenizerModeSection: some View {
        Section {
            Picker("Tokenizer Mode", selection: $vm.selectedTokenizerMode) {
                ForEach(HudViewModel.TokenizerMode.allCases, id: \.self) { mode in
                    Text(mode.displayName)
                        .tag(mode)
                }
            }
        } footer: {
            Text("Indo-European language will be always tokenized “By Word”.")
                .textCase(.none)
        }
    }

    var fontSection: some View {
        Section {
            Picker("Font", selection: $vm.selectedFont) {
                ForEach(HudViewModel.FontType.allCases, id: \.self) { font in
                    Text(font.displayName)
                        .tag(font)
                }
            }
        }
    }

    var opacitySection: some View {
        Section {
            Slider(
                value: $vm.opacity,
                in: vm.minimumOpacity...vm.maximumOpacity
            )
        } header: {
            HStack {
                Text("Opacity")
                Spacer()
                Text(String(format: "%.0f%%", vm.opacity * 100.0))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var yOffsetSection: some View {
        Section {
            Slider(
                value: $vm.yOffset,
                in: vm.minimumYOffset...vm.maximumYOffset
            )
        } header: {
            HStack {
                Text("Y Offset")
                Spacer()
                Text(String(format: "%.1fpt", vm.yOffset))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleBirthRateSection: some View {
        Section {
            Slider(
                value: $vm.birthRate,
                in: vm.minimumBirthRate...vm.maximumBirthRate
            )
        } header: {
            HStack {
                Text("Particle Birth Rate")
                Spacer()
                Text(String(format: "%.0f/s", vm.birthRate))
                    .monospacedDigit()
            }
            .textCase(.none)
        } footer: {
            Text("Sets the rate to zero to disable the particle effect.")
                .textCase(.none)
        }
    }

    var particleRangeSection: some View {
        Section {
            Slider(
                value: $vm.widthRatio,
                in: vm.minimumWidthRatio...vm.maximumWidthRatio
            )
        } header: {
            HStack {
                Text("Particle Range")
                Spacer()
                Text(String(format: "%.1fx", vm.widthRatio))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleSizeSection: some View {
        Section {
            Slider(
                value: $vm.fontSize,
                in: vm.minimumFontSize...vm.maximumFontSize
            )
        } header: {
            HStack {
                Text("Particle Size")
                Spacer()
                Text(String(format: "%.1fpt", vm.fontSize))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var yParticleSlideSection: some View {
        Section {
            Slider(
                value: $vm.ySlide,
                in: vm.minimumYSlide...vm.maximumYSlide
            )
        } header: {
            HStack {
                Text("Particle Y Slide")
                Spacer()
                Text(String(format: "%.1fpt", vm.ySlide))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleLifespanSection: some View {
        Section {
            Slider(
                value: $vm.lifespan,
                in: vm.minimumLifespan...vm.maximumLifespan
            )
        } header: {
            HStack {
                Text("Particle Lifespan")
                Spacer()
                Text(String(format: "%.2fs", vm.lifespan))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleSpeedSection: some View {
        Section {
            Slider(
                value: $vm.speed,
                in: vm.minimumSpeed...vm.maximumSpeed
            )
        } header: {
            HStack {
                Text("Particle Speed")
                Spacer()
                Text(String(format: "%.2fx", vm.speed))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleSpeedVariationSection: some View {
        Section {
            Slider(
                value: $vm.speedVariation,
                in: vm.minimumSpeedVariation...vm.maximumSpeedVariation
            )
        } header: {
            HStack {
                Text("Particle Speed Variation")
                Spacer()
                Text(String(format: "%.2fx", vm.speedVariation))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleBurstCountSection: some View {
        Section {
            Slider(
                value: $vm.burstCount,
                in: vm.minimumBurstCount...vm.maximumBurstCount
            )
        } header: {
            HStack {
                Text("Particle Burst Count")
                Spacer()
                Text(String(format: "%.0f", vm.burstCount))
                    .monospacedDigit()
            }
            .textCase(.none)
        } footer: {
            Text("Sets the rate to zero to disable the particle burst effect.")
                .textCase(.none)
        }
    }

    var particleBurstCountVariationSection: some View {
        Section {
            Slider(
                value: $vm.burstCountVariation,
                in: vm.minimumBurstCountVariation...vm.maximumBurstCountVariation
            )
        } header: {
            HStack {
                Text("Particle Burst Count Variation")
                Spacer()
                Text(String(format: "%.0f", vm.burstCountVariation))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleAttractionStrengthSection: some View {
        Section {
            Slider(
                value: $vm.attractionStrength,
                in: vm.minimumAttractionStrength...vm.maximumAttractionStrength
            )
        } header: {
            HStack {
                Text("Particle Attraction Strength")
                Spacer()
                Text(String(format: "%.1fx", vm.attractionStrength))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleDampingFactorSection: some View {
        Section {
            Slider(
                value: $vm.dampingFactor,
                in: vm.minimumDampingFactor...vm.maximumDampingFactor
            )
        } header: {
            HStack {
                Text("Particle Damping Factor")
                Spacer()
                Text(String(format: "%.1fx", vm.dampingFactor))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleInitialMultiplierSection: some View {
        Section {
            Slider(
                value: $vm.initialSize,
                in: vm.minimumInitialSize...vm.maximumInitialSize
            )
        } header: {
            HStack {
                Text("Initial Size Multiplier")
                Spacer()
                Text(String(format: "%.1fx", vm.initialSize))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var particleFinalMultiplierSection: some View {
        Section {
            Slider(
                value: $vm.sizeMultiplier,
                in: vm.minimumSizeMultiplier...vm.maximumSizeMultiplier
            )
        } header: {
            HStack {
                Text("Final Size Multiplier")
                Spacer()
                Text(String(format: "%.1fx", vm.sizeMultiplier))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var labelSection: some View {
        Section {
            Toggle(isOn: $vm.isLabelEnabled) {
                Text("Enable Accessory Label")
            }
        } header: {
            Text("Accessory Label")
                .textCase(.none)
        }
    }

    var labelFontSizeSection: some View {
        Section {
            Slider(
                value: $vm.labelFontSize,
                in: vm.minimumLabelFontSize...vm.maximumLabelFontSize
            )
        } header: {
            HStack {
                Text("Accessory Label: Font Size")
                Spacer()
                Text(String(format: "%.1fpt", vm.labelFontSize))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var yLabelOffsetSection: some View {
        Section {
            Slider(
                value: $vm.yLabelOffset,
                in: vm.minimumYLabelOffset...vm.maximumYLabelOffset
            )
        } header: {
            HStack {
                Text("Accessory Label: Y Offset")
                Spacer()
                Text(String(format: "%.1fpt", vm.yLabelOffset))
                    .monospacedDigit()
            }
            .textCase(.none)
        }
    }

    var resetSection: some View {
        Section {
            Button("Reset to Defaults", role: .destructive) {
                isAlertPresented = true
            }
        }
    }
}
