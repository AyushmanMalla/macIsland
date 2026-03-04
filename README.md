# 🏝️ macIsland

A high-performance, elegant macOS utility that anchors to your hardware notch. It provides a **Pomodoro Timer** and **Now Playing** media controls with fluid GPU-accelerated visualizations.

![macIsland Preview](https://github.com/user-attachments/assets/placeholder-notch-preview.png)

## ✨ Features

- **🎯 Notch-Anchored UI**: Perfectly centered above your MacBook's camera notch.
- **⏱️ Pomodoro Timer**: Stay productive with 25/5/15 minute cycles.
- **🎵 Media Controls**: Apple Music, Spotify, and YouTube control directly from the notch.
- **⚡ Performance Optimized**:
  - **~0.0% Idle CPU**: Pure event-driven hover monitoring (no polling).
  - **Metal-Backed Rendering**: All animations (`.drawingGroup()`) are offloaded to the GPU for battery-friendly 60/120fps motion.
  - **CoreAnimation Native**: Smooth spring transitions for expansion and collapse.
- **🪄 Stealth Mode**: No Dock icon, lives entirely in your display's "auxiliary head" area.

## 🚀 Getting Started

### Prerequisites
- macOS 15.0 or later (Tailored for MacBook Pro/Air with a hardware notch).
- Xcode 16.0+ (if building from source).

### Installation (Build from Source)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ayushman/macIsland.git
   cd macIsland
   ```

2. **Open the project in Xcode:**
   ```bash
   open macIsland.xcodeproj
   ```

3. **Build and Run:**
   - Select the `macIsland` scheme in Xcode.
   - Press `Command + R`.

## 🛠️ Configuration

The app is an `LSUIElement` (Agent app). It does **not** have a Dock icon.
- **Hover**: Move your mouse to the top-center of your screen to expand the widget.
- **Expand**: See your current track, album art, and timer progress.
- **Collapse**: The widget shrinks back into the notch when the mouse leaves.

## 🏗️ Tech Stack

- **SwiftUI**: Declarative UI layer.
- **AppKit (NSPanel)**: Custom non-activating window surfacing for notch anchoring.
- **MediaRemote**: Private framework bridge for system-wide media metadata.
- **Metal/CoreAnimation**: Hardware-accelerated transitions and waveforms.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
