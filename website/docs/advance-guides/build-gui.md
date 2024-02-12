---
sidebar_position: 1
title: Build SEGUL GUI  from source
---

## Build SEGUL GUI from source

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Rust](https://www.rust-lang.org/tools/install)
- [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/)
- [Android Studio](https://developer.android.com/studio)
- [Xcode (for iOS/iPadOS/macOS builds)](https://developer.apple.com/xcode/)
- [Visual Studio Code (recommended)](https://code.visualstudio.com/)
- [Visual Studio (for Windows builds)](https://visualstudio.microsoft.com/)`
- [Git](https://git-scm.com/downloads)
- [GH CLI (recommended)](https://cli.github.com/)

### Install dependencies

#### Install Flutter

Follow the instructions to install Flutter [here](https://flutter.dev/docs/get-started/install).

#### Install Rust

Follow the instructions to install Rust [here](https://www.rust-lang.org/tools/install).

#### Install Flutter Rust Bridge

Follow the instructions to install Flutter Rust Bridge (FRB) [here](https://cjycode.com/flutter_rust_bridge/). We use FRB v2.

### Clone the repository

```bash
gh repo clone hhandika/segui
```

Install Flutter dependencies:

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

### Build for Apple Devices

You need to have a macOS machine and Xcode installed to build for Apple Devices.

#### Install Xcode

Follow the instructions to install Xcode [here](https://developer.apple.com/xcode/).

#### Build SEGUI for macOS

```bash
flutter build macos --release
```

#### Build for iOS/iPadOS

```bash
flutter build ios --release
```

### Build for Linux

#### Install Linux dependencies

Follow the instructions to install Linux dependencies [here](https://docs.flutter.dev/platform-integration/linux/building).

```bash
flutter build linux --release
```

### Build for Android

```bash
flutter build apk --release
```
