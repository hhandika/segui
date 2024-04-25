---
sidebar_position: 2
title: Building SEGUL GUI  from source
description: Learn SEGUL GUI build process.
---

For most users, building the GUI version from source may not be necessary. However, this guide is useful if you wish to contribute to the project or build similar apps.

### Prerequisites

The GUI version of SEGUL is built using the Flutter framework. We use Dart as the programming language for the GUI. The Dart code communicates with the SEGUL core library via a foreign function interface (FFI). We simplify this process by using the Flutter Rust Bridge (FRB) library that generates the FFI code for us. Learn more about the SEGUL architecture [here](/docs/advance-guides/architecture).

To build the GUI version of SEGUL, install the following tools:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Rust](https://www.rust-lang.org/tools/install)
- [Flutter Rust Bridge](https://cjycode.com/flutter_rust_bridge/)
- [Android Studio](https://developer.android.com/studio)
- [Xcode (for iOS/iPadOS/macOS builds)](https://developer.apple.com/xcode/)
- [Visual Studio Code (recommended)](https://code.visualstudio.com/)
- [Visual Studio (for Windows builds)](https://visualstudio.microsoft.com/)`
- [Git](https://git-scm.com/downloads)
- [GH CLI (recommended)](https://cli.github.com/)

#### Install Flutter

Follow the instructions to install Flutter [here](https://flutter.dev/docs/get-started/install). It will also guide you to install Android Studio and other required dependencies.

#### Install Rust

Follow the instructions to install Rust [here](https://www.rust-lang.org/tools/install).

#### Install Flutter Rust Bridge

Follow the instructions to install Flutter Rust Bridge (FRB) [here](https://cjycode.com/flutter_rust_bridge/). We use FRB v2. You will need to install the CLI tool through Cargo and the FRB package for Flutter. Keep in mind that the version of the FRB CLI tool and the FRB package must match.

### Clone the repository

We use GitHub CLI tool here.

```bash
gh repo clone hhandika/segui
```

If you are using git:

```bash
git clone https://github.com/hhandika/segui.git
```

Then, change the directory to segui directory. Install Flutter dependencies:

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
