---
sidebar_position: 2
title: GUI Installation
---

The GUI version, SEGUI, is currently in beta. Everyone is welcome to try the application and report bugs.

- [Android](#android)
- [Apple Devices](#apple-devices)
- [Linux](#linux)
- [Windows](#windows)

## Android

SEGUI works on Android phones and tablets.

Requirements

- Android 8 Oreo+ (SDK 26)

Download the apk file from [here](https://github.com/hhandika/segui/releases). Then, install the app on your Android device. You may need to allow installation from unknown sources. Depending on your devices, usually you can do this by going to Settings > Apps & notifications > Advanced > Special app access > Install unknown apps. Then, select the browser you use to download the apk file.

## Apple Devices

SEGUI works on iPhones, iPads, and Macs.

Requirements

- iOS 12.0+ (recommended iOS 16.0+)
- iPadOS 13.0+
- macOS 11.0+ (recommended macOS Ventura 13.0+)

Due to Apple's stringent security policy, testing SEGUI requires the installation of the Apple [TestFlight](https://developer.apple.com/testflight/) app. You can install the beta version of the app on Apple devices by following [this link](https://testflight.apple.com/join/LSJD5D0i).

## Linux

Requirements

- Ubuntu 22.04+
- openSUSE Tumbleweed (tested)

Download the latest release from [here](https://github.com/hhandika/segui/releases). Extract the `segui-Linux-x86_64.tar.gz` file to your desired location.

Open terminal and extract the file using the following command:

```bash
tar -xvzf segui-Linux-x86_64.tar.gz
```

Then, run the `segui` executable.

:::info
The app may work on any Linux distribution with 64-bit architecture and GLIBC 2.34+.

To check your GLIBC version, run the following command in the terminal:

```bash
ldd --version
```

:::

## Windows

Requirements

- Windows 10+ (64-bit)

Download the latest release from [here](https://github.com/hhandika/segui/releases). Extract the `segui-Windows-x86_64.zip` file to your desired location. Then, run the `segui.exe` file. You can also create a shortcut to the file for easier access.
