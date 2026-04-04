//
//  HudFirefliesView.swift
//  Letterpress
//
//  Created by Rachel on 8/6/2025.
//

import SwiftUI
import Vortex

/// A sample view demonstrating fireflies that are repelled from the user's touch.
struct HudFirefliesView: View {
    @StateObject var vm = HudViewModel.shared

    @State var system = VortexSystem(
        tags: (0..<HudViewModel.characterCount).map { "circle\($0)" },
        shape: .ellipse(radius: 0.25),
        birthRate: 100.0,
        burstCount: 0,
        burstCountVariation: 0,
        lifespan: 3.0,
        speed: 0,
        speedVariation: 0.25,
        angleRange: .degrees(360),
        attractionStrength: -1.6,
        dampingFactor: 1.0,
        colors: .ramp(.white, .white.opacity(0)),
        size: 0.2,
        sizeMultiplierAtDeath: 5.0
    )

    var initialRenderColors: [VortexSystem.Color] {
        let colors = HudViewModel.shared.suggestedColors ?? HudViewModel.shared.colors
        if colors.isEmpty {
            return [.white, .white.opacity(0)]
        }
        return colors
    }

    var renderColors: [VortexSystem.Color] {
        let colors = vm.suggestedColors ?? vm.colors
        if colors.isEmpty {
            return [.white, .white.opacity(0)]
        }
        return colors
    }

    init() {
        let vm = HudViewModel.shared
        system.birthRate = vm.birthRate
        system.lifespan = vm.lifespan
        system.speed = vm.speed
        system.speedVariation = vm.speedVariation
        system.burstCount = vm.burstCount
        system.burstCountVariation = vm.burstCountVariation
        system.attractionStrength = vm.attractionStrength
        system.dampingFactor = vm.dampingFactor
        system.size = vm.initialSize
        system.sizeMultiplierAtDeath = vm.sizeMultiplier
        system.colors = .ramp(initialRenderColors)
    }

    var attributesHash: Int {
        combines(
            vm.ySlide,
            vm.widthRatio,
            vm.birthRate,
            vm.lifespan,
            vm.speed,
            vm.speedVariation,
            vm.burstCount,
            vm.burstCountVariation,
            vm.attractionStrength,
            vm.dampingFactor,
            vm.initialSize,
            vm.sizeMultiplier,
            renderColors
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if vm.birthRate > 1e-3 || vm.burstCount > 0 {
                    VortexViewReader { proxy in
                        particleBody
                            .onAppear { reloadAttributes(geometry: geometry, proxy: proxy) }
                            .onChange(of: attributesHash) { _ in
                                reloadAttributes(geometry: geometry, proxy: proxy)
                            }
                            .onChange(of: vm.content) { _ in
                                if vm.burstCount > 0 {
                                    proxy.burst()
                                }
                            }
                    }
                    .transition(.opacity)
                }

#if DEBUG
                Capsule()
                    .fill(.black)
                    .frame(width: 120, height: 36)
#endif

                if vm.isLabelEnabled {
                    textBody
                        .frame(maxWidth: geometry.size.width - 16)
                        .transition(.opacity)
                        .offset(y: vm.yLabelOffset)
                        .modify { body in
                            if #available(iOS 16, *) {
                                body.contentTransition(.interpolate)
                            } else {
                                body
                            }
                        }
                }
            }
            .opacity(vm.opacity)
            .animation(.easeIn(duration: 0.5), value: combines(
                vm.birthRate > 1e-3,
                vm.isLabelEnabled
            ))
            .animation(.easeOut(duration: 1.0), value: combines(
                vm.content,
                vm.shuffledComponents
            ))
            .frame(
                width: geometry.size.width * vm.widthRatio,
                height: geometry.size.width * vm.widthRatio * 0.667
            )
            .offset(
                x: -geometry.size.width * (vm.widthRatio / 2 - 0.5),
                y: -geometry.size.width * (vm.widthRatio / 2 - 0.5) * 0.667
            )
        }
        .offset(y: vm.yOffset)
    }

    var particleBody: some View {
        VortexView(system) {
            ForEach(0..<HudViewModel.characterCount, id: \.self) { index in
                if let char = component(vm.shuffledComponents, at: index) {
                    textParticle(char, index: index)
                } else {
                    circleParticle(index: index)
                }
            }
        }
    }

    @ViewBuilder
    func textParticle(_ text: String, index: Int) -> some View {
        VStack(alignment: .center) {
            Text(verbatim: text)
                .lineLimit(1)
                .truncationMode(.head)
                .foregroundStyle(.white)
                .font(vm.fontType.renderFont(size: vm.fontSize))
        }
        .frame(width: 200)
        .tag("circle\(index)")
    }

    @ViewBuilder
    func circleParticle(index: Int) -> some View {
        Circle()
            .fill(.white)
            .frame(width: vm.fontSize)
            .blur(radius: 3)
            .tag("circle\(index)")
    }

    var textBody: some View {
        Text(vm.content)
            .lineLimit(2)
            .foregroundStyle(.white)
            .font(vm.fontType.renderFont(size: vm.labelFontSize))
            .opacity(vm.content.isEmpty ? 0.0 : 1.0)
            .background(.black.opacity(0.5), ignoresSafeAreaEdges: [])
    }

    func component(_ components: [String], at index: Int) -> String? {
        if index < 0 || index >= components.count {
            return nil
        }
        let str = components[index]
        if str == "⬤" {
            return nil
        }
        return str
    }

    func reloadAttributes(geometry: GeometryProxy, proxy: VortexProxy) {
        proxy.attractTo(CGPoint(
            x: geometry.size.width * vm.widthRatio / 2,
            y: geometry.size.width * vm.widthRatio * 0.667 / 2 + vm.ySlide
        ))
        proxy.particleSystem?.birthRate = vm.birthRate
        proxy.particleSystem?.lifespan = vm.lifespan
        proxy.particleSystem?.speed = vm.speed
        proxy.particleSystem?.speedVariation = vm.speedVariation
        proxy.particleSystem?.burstCount = vm.burstCount
        proxy.particleSystem?.burstCountVariation = vm.burstCountVariation
        proxy.particleSystem?.attractionStrength = vm.attractionStrength
        proxy.particleSystem?.dampingFactor = vm.dampingFactor
        proxy.particleSystem?.size = vm.initialSize
        proxy.particleSystem?.sizeMultiplierAtDeath = vm.sizeMultiplier
        proxy.particleSystem?.colors = .ramp(renderColors)
    }
}
