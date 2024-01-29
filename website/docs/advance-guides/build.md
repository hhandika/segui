---
sidebar_position: 1
title: Build SEGUL GUI from source
---

## Build SEGUL GUI from source

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Android Studio](https://developer.android.com/studio)
- [Xcode (for iOS/iPadOS/macOS builds)](https://developer.apple.com/xcode/)
- [Visual Studio Code (recommended)](https://code.visualstudio.com/)
- [Visual Studio (for Windows builds)](https://visualstudio.microsoft.com/)`
- [Git](https://git-scm.com/downloads)
- [GH CLI (recommended)](https://cli.github.com/)
- [Rust](https://www.rust-lang.org/tools/install)

### Clone the repository

```bash
gh repo clone hhandika/segui
```

### Install dependencies

```bash
cd segui

flutter pub get
```

### Run the app

```bash

flutter run
```

### Build for windows

```bash
flutter build windows --release
```

### Build for macOS

```bash
flutter build macos --release
```

### Build for Linux

```bash
flutter build linux --release
```

### Build for Android

```bash
flutter build apk --release
```

### Build for iOS/iPadOS

```bash
flutter build ios --release
```
