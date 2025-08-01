# BitProwler

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
![iOS](https://img.shields.io/badge/iOS-18.1+-green.svg)
![Swift](https://img.shields.io/badge/Swift-5.10+-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-16.1+-blue.svg)

BitProwler is a sleek, native iOS application designed to be the ultimate mobile companion for managing your [Prowlarr](https://prowlarr.com/) and [qBittorrent](https://www.qbittorrent.org/) servers. It provides a unified, intuitive interface to search for new content and manage your active torrents, all from the palm of your hand.

---

## 📸 Screenshots

<!-- TODO: Replace these placeholders with actual screenshots of the app. A GIF showing the search-to-add workflow would be fantastic! -->

| Search View | Torrents List | Torrent Actions |
| :---: |:---:|:---:|
| <img src="" width="250"> | <img src="" width="250"> | <img src="" width="250"> |

## ✨ Features

BitProwler is packed with features to streamline your workflow.

#### Prowlarr Integration
- **Unified Search**: Seamlessly search across all your Prowlarr-configured indexers with a single query.
- **Advanced Sorting**: Sort search results by seeders, size, or publish date to find exactly what you need.
- **Smart Filtering**: Create and manage custom keyword filters to include or exclude results based on your criteria. Apply filters with AND/OR logic.
- **Search History**: Quickly access your recent searches.

#### qBittorrent Management
- **Live Torrent List**: View and monitor all your active torrents with real-time updates on progress, speed, and status.
- **Comprehensive Actions**:
    - Pause, resume, and force start torrents.
    - Delete torrents (with or without downloaded data).
    - Move torrents to a new location on your server.
    - Recheck torrent integrity.
- **Add Torrents on the Go**: Add new torrents directly from the search view, or manually using a magnet link or a `.torrent` file.
- **Detailed View**: Tap a torrent to see detailed stats, or tap a search result for more information before downloading.
- **File Inspector**: View the individual files and their completion status within a torrent.
- **Path Management**: Remembers and suggests recent download paths for convenience.

#### General App Features
- **Modern UI**: A clean and responsive interface built entirely with SwiftUI.
- **Multi-Server Support**: Configure and switch between multiple Prowlarr and qBittorrent servers.
- **Secure**: Server credentials and API keys are stored securely in the device's Keychain.
- **Light & Dark Mode**: Fully supports system-wide appearance settings.

## 📋 Requirements
- **iOS 18.1** or later.
- **Xcode 16.1** or later to build.
- A self-hosted **Prowlarr** instance.
- A self-hosted **qBittorrent** instance with the WebUI enabled.

## 🚀 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/ProwlarriOS.git
    cd ProwlarriOS
    ```
2.  **Open the project:**
    Open `ProwlarriOS.xcodeproj` in Xcode. The project uses Swift Package Manager to handle dependencies, which will be resolved automatically.

3.  **Build and Run:**
    Select your device or a simulator and press `Cmd+R` to build and run the app.

### Configuration
The app is not functional until you configure your servers.
1.  Launch the app.
2.  Navigate to the **Settings** tab.
3.  Select **Prowlarr Servers** and add your server's URL and API key.
4.  Select **qBittorrent Servers** and add your server's URL, username, and password.
5.  Once added, make sure to select an active server for each service. The active server is indicated by a checkmark.

## 🛠️ Technology Stack & Project Structure

BitProwler is built with modern Apple technologies and follows a clean, MVVM-inspired architecture.

-   **UI**: SwiftUI
-   **Concurrency**: Swift Concurrency (`async`/`await`)
-   **Networking**: `URLSession`
-   **Data Persistence**: `UserDefaults` for settings, `KeychainAccess` for secure credentials.

The project structure is organized for clarity and scalability:

```
ProwlarriOS/
├── App/                # Main app entry point
├── Assets.xcassets/    # App icons, colors, etc.
├── Errors/             # Custom error types (AppError)
├── Extensions/         # Swift extensions for core types
├── Managers/           # Global state managers (Server, History)
├── Models/             # Data models (TorrentResult, QBittorrentTorrent)
├── Networking/         # API services and network layer
├── Preview Content/    # Assets for SwiftUI Previews
├── Utils/              # Utility code
└── Views/              # All SwiftUI views, organized by feature
    ├── Components/     # Reusable view components (rows, buttons)
    ├── Settings/       # Views related to the settings tab
    ├── ContentView.swift
    ├── SearchView.swift
    ├── TorrentDetailView.swift
    └── TorrentsView.swift
```

## 🤝 How to Contribute

Contributions are welcome! Whether it's a bug report, feature request, or a pull request, your help is appreciated.

1.  **Fork** the repository.
2.  Create a new branch: `git checkout -b feature/my-new-feature`.
3.  Make your changes and commit them: `git commit -am 'Add some feature'`.
4.  Push to the branch: `git push origin feature/my-new-feature`.
5.  Submit a **Pull Request**.

Please open an issue first to discuss any major changes you would like to make.

## 📜 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Leonardo Solari

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 🙏 Acknowledgements

-   The teams behind [Prowlarr](https://prowlarr.com/) and [qBittorrent](https://www.qbittorrent.org/) for creating such powerful tools.
-   [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) for a simple and secure way to interact with the iOS Keychain.