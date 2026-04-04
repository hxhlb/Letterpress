//
//  HudViewModel.swift
//  Letterpress
//
//  Created by Rachel on 8/6/2025.
//

import Combine
import notify
import SwiftUI
#if os(iOS)
import TRHudObjC
#endif
import Vortex

let LetterpressNotificationNameNeedsReload = "LetterpressNotificationNameNeedsReload"

final class HudViewModel: ObservableObject {
    static let shared = HudViewModel()
    static let characterCount = 20

    static let userDefaults: UserDefaults = {
#if os(iOS)
#if targetEnvironment(simulator)
        return GetStandardUserDefaults()
#else
        return GetSystemUserDefaults(Bundle.main.bundleIdentifier!)
#endif
#else
        return .standard
#endif
    }()

    private var cancellables = Set<AnyCancellable>()

    @Published var isActivated = false
    @Published var shuffledComponents: [String] = []
    @Published var content: String = ""

    private var timer: Timer?

    enum FontType: String, CaseIterable {
        case pingFang
        case helveticaNeue
        case avenirNext
        case futura
        case georgia
        case fangSong
        case kaiTi

        var displayName: LocalizedStringKey {
            switch self {
            case .pingFang:
                return "PingFang"
            case .fangSong:
                return "ZhuqueFangsong"
            case .kaiTi:
                return "LXGWWenKai"
            case .helveticaNeue:
                return "Helvetica Neue"
            case .avenirNext:
                return "Avenir Next"
            case .futura:
                return "Futura"
            case .georgia:
                return "Georgia"
            }
        }

        func renderFont(size: CGFloat) -> Font {
            switch self {
            case .pingFang:
                .system(size: size, weight: .regular, design: .default)
            case .fangSong:
                .custom("ZhuqueFangsong-Regular", size: size)
            case .kaiTi:
                .custom("LXGWWenKaiLite-Medium", size: size)
            case .helveticaNeue:
                .custom("Helvetica Neue", size: size)
            case .avenirNext:
                .custom("Avenir Next", size: size)
            case .futura:
                .custom("Futura", size: size)
            case .georgia:
                .custom("Georgia", size: size)
            }
        }
    }

    enum TokenizerMode: String, CaseIterable {
        case byCharacter
        case byWord

        var displayName: LocalizedStringKey {
            switch self {
            case .byCharacter:
                return "By Character"
            case .byWord:
                return "By Word"
            }
        }
    }

    @AppStorage("fontType", store: userDefaults)
    private var storedFontType: String = FontType.pingFang.rawValue
    @Published var fontType: FontType = .pingFang

    @AppStorage("tokenizerMode", store: userDefaults)
    private var storedTokenizerMode: String = TokenizerMode.byCharacter.rawValue
    @Published var tokenizerMode: TokenizerMode = .byCharacter

    @AppStorage("widthRatio", store: userDefaults)
    private var storedWidthRatio: Double = 1.6
    @Published var widthRatio: CGFloat = 1.6

    @AppStorage("yOffset", store: userDefaults)
    private var storedYOffset: Double = 0.0
    @Published var yOffset: CGFloat = 0.0

    @AppStorage("ySlide", store: userDefaults)
    private var storedYSlide: Double = -10.0
    @Published var ySlide: CGFloat = -10.0

    @AppStorage("fontSize", store: userDefaults)
    private var storedFontSize: Double = 20.0
    @Published var fontSize: CGFloat = 20.0

    @AppStorage("birthRate", store: userDefaults)
    private var storedBirthRate: Double = 100.0
    @Published var birthRate: Double = 100.0

    @AppStorage("lifespan", store: userDefaults)
    private var storedLifespan: Double = 3.0
    @Published var lifespan: Double = 3.0

    @AppStorage("speed", store: userDefaults)
    private var storedSpeed: Double = 0.0
    @Published var speed: CGFloat = 0.0

    @AppStorage("speedVariation", store: userDefaults)
    private var storedSpeedVariation: Double = 0.25
    @Published var speedVariation: CGFloat = 0.25

    @AppStorage("burstCount")
    private var storedBurstCount: Double = 0
    @Published var burstCount: Int = 0

    @AppStorage("burstCountVariation")
    private var storedBurstCountVariation: Double = 0
    @Published var burstCountVariation: Int = 0

    @AppStorage("attractionStrength", store: userDefaults)
    private var storedAttractionStrength: Double = -1.6
    @Published var attractionStrength: CGFloat = -1.6

    @AppStorage("dampingFactor", store: userDefaults)
    private var storedDampingFactor: Double = 1.0
    @Published var dampingFactor: CGFloat = 1.0

    @AppStorage("initialSize", store: userDefaults)
    private var storedInitialSize: Double = 0.2
    @Published var initialSize: CGFloat = 0.2

    @AppStorage("sizeMultiplier", store: userDefaults)
    private var storedSizeMultiplier: Double = 5.0
    @Published var sizeMultiplier: CGFloat = 5.0

    @AppStorage("isLabelEnabled", store: userDefaults)
    private var storedIsLabelEnabled: Bool = false
    @Published var isLabelEnabled: Bool = false

    @AppStorage("labelFontSize", store: userDefaults)
    private var storedLabelFontSize: Double = 20.0
    @Published var labelFontSize: CGFloat = 20.0

    @AppStorage("yLabelOffset", store: userDefaults)
    private var storedYLabelOffset: Double = 0.0
    @Published var yLabelOffset: CGFloat = 0.0

    @AppStorage("opacity", store: userDefaults)
    private var storedOpacity: Double = 1.0
    @Published var opacity: CGFloat = 1.0

    @AppStorage("color1", store: userDefaults)
    private var storedColor1: String = "1.0,1.0,0.0,1.0"
    @AppStorage("color2", store: userDefaults)
    private var storedColor2: String = "1.0,0.0,0.0,1.0"
    @AppStorage("color3", store: userDefaults)
    private var storedColor3: String = "1.0,1.0,1.0,0.0"
    @AppStorage("color4", store: userDefaults)
    private var storedColor4: String = "1.0,1.0,1.0,0.0"

    @Published var colors: [VortexSystem.Color] = []
    @Published var suggestedColors: [VortexSystem.Color]?
    private var selectedApplications: Set<String> = []

    init() {
#if os(iOS)
        guard let eventProxy, isCommandLineHud else {
            return
        }

        registerUserDefaults()
        isActivated = eventProxy.isAppInForeground.value && eventProxy.isHudVisible.value
        selectedApplications = Set(Self.userDefaults.stringArray(forKey: "selectedApplications") ?? [])

        Publishers.CombineLatest4(
            eventProxy.isAppInForeground,
            eventProxy.isHudVisible,
            eventProxy.isNowPlaying,
            eventProxy.nowPlayingApp
        )
        .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
        .sink { [unowned self] (isAppInForeground, isHudVisible, isNowPlaying, nowPlayingApp) in
            let newActivated = (isAppInForeground || (isNowPlaying && isEligibleNowPlayingApp(nowPlayingApp))) && isHudVisible
            if isActivated != newActivated {
#if DEBUG
                print("foreground: \(isAppInForeground), visible: \(isHudVisible), now playing: \(isNowPlaying), app: \(nowPlayingApp ?? "")")
#endif
                isActivated = newActivated
            }
            reloadTestTimer()
        }
        .store(in: &cancellables)

        eventProxy.nowPlayingSubtitle
            .sink { [unowned self] subtitle in
                updateContent(subtitle)
            }
            .store(in: &cancellables)

        eventProxy.nowPlayingArtworkColors
            .sink { [unowned self] colors in
#if DEBUG
                print("artwork colors: \(String(describing: colors ?? []))")
#endif
                suggestedColors = colors?.map(VortexSystem.Color.init)
            }
            .store(in: &cancellables)

        var token: Int32 = 0
        notify_register_dispatch(
            LetterpressNotificationNameNeedsReload,
            &token,
            DispatchQueue.main
        ) { [unowned self] _ in
            reloadUserDefaults()
        }

        reloadUserDefaults()
        reloadTestTimer()
#else
        isActivated = true
        reloadUserDefaults()
        reloadTestTimer()
#endif
    }

    private func reloadUserDefaults() {
        fontType = FontType(rawValue: storedFontType) ?? .pingFang
        tokenizerMode = TokenizerMode(rawValue: storedTokenizerMode) ?? .byCharacter
        widthRatio = CGFloat(storedWidthRatio)
        yOffset = CGFloat(storedYOffset)
        ySlide = CGFloat(storedYSlide)
        fontSize = CGFloat(storedFontSize)
        birthRate = storedBirthRate
        lifespan = storedLifespan
        speed = CGFloat(storedSpeed)
        speedVariation = CGFloat(storedSpeedVariation)
        burstCount = Int(round(storedBurstCount))
        burstCountVariation = Int(round(storedBurstCountVariation))
        attractionStrength = CGFloat(storedAttractionStrength)
        dampingFactor = CGFloat(storedDampingFactor)
        initialSize = CGFloat(storedInitialSize)
        sizeMultiplier = CGFloat(storedSizeMultiplier)
        opacity = CGFloat(storedOpacity)
        isLabelEnabled = storedIsLabelEnabled
        labelFontSize = storedLabelFontSize
        yLabelOffset = CGFloat(storedYLabelOffset)
        let rawColors = [
            parseColor(from: storedColor1),
            parseColor(from: storedColor2),
            parseColor(from: storedColor3),
            parseColor(from: storedColor4),
        ].filter { $0.opacity > 1e-3 }
        colors = rawColors + [.clear.opacity(0)]
        selectedApplications = Set(
            Self.userDefaults.stringArray(forKey: "selectedApplications") ?? []
        )
    }

    private func parseColor(from string: String) -> VortexSystem.Color {
        let components = string.split(separator: ",").compactMap { Double($0) }
        guard components.count == 4 else { return .clear }
        return VortexSystem.Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }

    private func reloadTestTimer() {
#if os(iOS)
        guard let eventProxy else { return }

        let shouldSetupTest = isActivated && !eventProxy.isNowPlaying.value && eventProxy.isAppInForeground.value

        if shouldSetupTest && timer == nil {
            testUpdateContent()
            timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
                self?.testUpdateContent()
            }
        } else if !shouldSetupTest && timer != nil {
            timer?.invalidate()
            timer = nil
        }
#else
        testUpdateContent()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.testUpdateContent()
        }
#endif
    }

    private func testUpdateContent() {
        let testLyricLines = NSLocalizedString("TEST_LYRICS", comment: "")
        let testLines = testLyricLines.components(separatedBy: "\n")
        updateContent(testLines[Int.random(in: 0..<testLines.count)])
    }

    private func updateContent(_ content: String?) {
        let trimmedContent = content?
            .components(separatedBy: .whitespacesAndNewlines).joined(separator: " ")

        guard self.content != trimmedContent else {
            return
        }

#if DEBUG
        print("subtitle: \(trimmedContent ?? "")")
#endif

        self.content = trimmedContent ?? ""
        if let comps = trimmedContent?.hudTokenized(
            byCharacter: tokenizerMode == .byCharacter,
            minimumCount: 20,
            shuffled: true
        ), !comps.isEmpty {
            self.shuffledComponents = comps
        } else {
            self.shuffledComponents = Array(repeating: "⬤", count: 20)
        }
    }

    private func isEligibleNowPlayingApp(_ app: String?) -> Bool {
        guard let app else { return false }
        return selectedApplications.contains(app)
    }
}

extension VortexSystem.Color {
    init(_ color: Color) {
#if os(iOS)
        let cgColor = UIColor(color).cgColor
#else
        let cgColor = NSColor(color).cgColor
#endif
        if cgColor.numberOfComponents == 1 {
            self.init(white: cgColor.components![0])
        } else if cgColor.numberOfComponents == 2 {
            self.init(white: cgColor.components![0], opacity: cgColor.components![1])
        } else if cgColor.numberOfComponents == 3 {
            self.init(red: cgColor.components![0],
                      green: cgColor.components![1],
                      blue: cgColor.components![2])
        } else if cgColor.numberOfComponents == 4 {
            self.init(red: cgColor.components![0],
                      green: cgColor.components![1],
                      blue: cgColor.components![2],
                      opacity: cgColor.components![3])
        } else {
            self.init(white: 1, opacity: 0)
        }
    }
}
