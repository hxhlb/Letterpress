<div align="center">

<img src="Artworks/HavocMarketing.png" width="200" alt="Letterpress" />

# Letterpress

An awesome music visualizer for iOS.

一款精美的 iOS 音乐可视化应用。

[![Build and Release](https://github.com/OwnGoalStudio/Letterpress/actions/workflows/build-and-release.yml/badge.svg)](https://github.com/OwnGoalStudio/Letterpress/actions/workflows/build-and-release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)](https://developer.apple.com/ios/)

</div>

> [!NOTE]
> This project has reached **End of Life (EOL)** and is no longer actively maintained. It has been open-sourced under the MIT License for archival and educational purposes.
>
> 本项目已经停止维护（**EOL**），并以 MIT 协议开源，仅用于存档和学习用途。

---

## Table of Contents / 目录

- [English](#english)
- [中文](#中文)

---

## English

### Introduction

**Letterpress** is a music visualizer app for iOS that displays dynamic particle effects as a floating overlay on your screen. It renders animated "fireflies" that respond to the currently playing music and its lyrics, with colors automatically adapted from album artwork. Designed to work with TrollStore, it brings a stunning visual layer to your music listening experience.

### Features

- 🎵 **Real-Time Music Visualization** — Animated particle effects that react to your music and lyrics in real time.
- 🌈 **Adaptive Colors** — Particle colors are automatically extracted from the album artwork of the now-playing track.
- 🔤 **Lyric Display** — Supports text segmentation for Indo-European languages and CJK (Chinese, Japanese, Korean) characters, with both character-by-character and word-by-word tokenizer modes.
- 🪟 **Floating Overlay** — Works as a system-wide floating window, fitting seamlessly with the notch and Dynamic Island.
- 🎨 **Extensive Customization** — Fine-tune particle physics (birth rate, size, speed, lifespan, attraction, damping), fonts, colors, and positioning.
- 🔒 **Lock Screen Support** — Optionally display visualizations on the lock screen.
- 📸 **Screenshot Control** — Hide the visualizer from screenshots and screen recordings.
- 🎧 **Wide App Compatibility** — Works with Apple Music, Spotify (with [EeveeSpotify](https://github.com/whoeevee/EeveeSpotify)), YouTube Music (with [YTMusicUltimate](https://github.com/dayanch96/YTMusicUltimate)), QQ Music, NetEase Cloud Music, Kugou Music, Kuwo Music, and more — as long as the app pushes lyrics to Media Controls.
- 🖋️ **Multiple Fonts** — Built-in support for PingFang, ZhuqueFangsong, LXGWWenKai, Helvetica Neue, Avenir Next, Futura, Georgia, and a retro bitmap font.

### Compatibility

- **iOS Version**: iOS 15.0 and above (optimized for iOS 16+)
- **Installation**: Requires [TrollStore](https://github.com/opa334/TrollStore) for sideloading

### Building from Source

**Requirements:**

- macOS 14+
- Xcode 16.2+
- [Homebrew](https://brew.sh)

**Steps:**

1. Install dependencies:

   ```bash
   brew install xcbeautify ldid-procursus p7zip
   ```

2. Clone the [Theos](https://github.com/OwnGoalStudio/theos) build system:

   ```bash
   git clone --recursive -b fixture/letterpress https://github.com/OwnGoalStudio/theos.git ~/theos
   ```

3. Clone this repository and build:

   ```bash
   git clone https://github.com/OwnGoalStudio/Letterpress.git
   cd Letterpress
   ./devkit/compile.sh
   ```

4. The output `.tipa` file will be in the `packages/` directory. Install it using TrollStore.

---

## 中文

### 简介

**Letterpress** 是一款适用于 iOS 的音乐可视化应用，以浮动窗口的形式在屏幕上展示动态粒子特效。它能够根据正在播放的音乐和歌词，渲染随之律动的「萤火虫」粒子动画，并自动从专辑封面中提取配色方案。本应用需要搭配 TrollStore 使用，为你的音乐聆听体验增添一层令人惊艳的视觉效果。

### 功能特性

- 🎵 **实时音乐可视化** — 粒子动画实时响应当前播放的音乐与歌词。
- 🌈 **自适应配色** — 粒子颜色自动从当前播放曲目的专辑封面中提取。
- 🔤 **歌词展示** — 支持印欧语系文字分词以及 CJK（中日韩）字符分割，提供逐字和逐词两种分词模式。
- 🪟 **浮动窗口** — 以系统级浮动窗口形式运行，完美适配刘海屏和灵动岛。
- 🎨 **深度自定义** — 可精细调节粒子物理参数（产生速率、大小、速度、生命周期、引力、阻尼）、字体、颜色和位置。
- 🔒 **锁屏支持** — 可选择在锁屏界面上显示可视化效果。
- 📸 **截图控制** — 可在截图和录屏中隐藏可视化效果。
- 🎧 **广泛的应用兼容性** — 支持 Apple Music、Spotify（需配合 [EeveeSpotify](https://github.com/whoeevee/EeveeSpotify)）、YouTube Music（需配合 [YTMusicUltimate](https://github.com/dayanch96/YTMusicUltimate)）、QQ 音乐、网易云音乐、酷狗音乐、酷我音乐等——只要应用将歌词推送到媒体控制即可。
- 🖋️ **多字体支持** — 内置 PingFang（苹方）、朱雀仿宋、霞鹜文楷、Helvetica Neue、Avenir Next、Futura、Georgia 以及像素风格字体。

### 兼容性

- **iOS 版本**：iOS 15.0 及以上（针对 iOS 16+ 优化）
- **安装方式**：需通过 [TrollStore](https://github.com/opa334/TrollStore) 进行侧载安装

### 从源码构建

**环境要求：**

- macOS 14+
- Xcode 16.2+
- [Homebrew](https://brew.sh)

**构建步骤：**

1. 安装依赖：

   ```bash
   brew install xcbeautify ldid-procursus p7zip
   ```

2. 克隆 [Theos](https://github.com/OwnGoalStudio/theos) 构建系统：

   ```bash
   git clone --recursive -b fixture/letterpress https://github.com/OwnGoalStudio/theos.git ~/theos
   ```

3. 克隆本仓库并构建：

   ```bash
   git clone https://github.com/OwnGoalStudio/Letterpress.git
   cd Letterpress
   ./devkit/compile.sh
   ```

4. 输出的 `.tipa` 文件位于 `packages/` 目录下，使用 TrollStore 进行安装。

---

## Acknowledgments / 致谢

Letterpress is built with the following open-source projects:

Letterpress 基于以下开源项目构建：

- [Vortex](https://github.com/twostraws/Vortex) — Particle effects engine / 粒子特效引擎
- [DominantColors](https://github.com/DenDmitriev/DominantColors) — Album artwork color extraction / 专辑封面颜色提取
- [SwifterSwift](https://github.com/SwifterSwift/SwifterSwift) — Swift extensions / Swift 扩展工具集
- [SwiftUI Introspect](https://github.com/siteline/swiftui-introspect) — SwiftUI to UIKit bridge / SwiftUI 与 UIKit 桥接
- [SwiftUIBackports](https://github.com/shaps80/SwiftUIBackports) — SwiftUI backports for older iOS / SwiftUI 向后兼容
- [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) — Lightweight window management / 轻量窗口管理
- [DpkgVersion](https://github.com/Lakr233/DpkgVersion) — Debian package version comparison / Debian 包版本比较

## License / 许可证

This project is licensed under the [MIT License](LICENSE).

本项目基于 [MIT 许可证](LICENSE) 开源。

Copyright © 2025 Lessica
