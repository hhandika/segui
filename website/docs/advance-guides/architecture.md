---
sidebar_position: 1
title: App Design and Architecture
description: Learn how we design SEGUL app.
---

SEGUL is available as a GUI, CLI, and a library. All three versions share the same core functionalities. The SEGUL core library is written in Rust, a systems programming language that is known for its speed, memory safety, and parallelism. The GUI layer uses in [Flutter](https://flutter.dev/) and is written in Dart. The CLI is wrapped around the Rust library and is written in Rust.

## Repository Structure

We uses multi-repository structure to separate the GUI and SEGUL core library. The CLI is part of the SEGUL core library. The repository can be found in the following links:

- [SEGUL GUI](https://github.com/hhandika/segui)
- [SEGUL CLI and Core Library](https://github.com/hhandika/segul)

## Connecting the GUI and CLI

The GUI and CLI communicate through a bridge. The bridge is a Rust library that wraps the SEGUL core library. THe rust library can communicate with the GUI through the C-FFI (Foreign Function Interface) feature. We simplify creating the bridge by using the amazing [Flutter Rust Bridge (FRB)](https://cjycode.com/flutter_rust_bridge/). SEGUL use the version 2 of FRB.

:::note
If we were to redesign the repository structure, we would adopt a monorepo approach where the library, CLI, and GUI are all contained within a single repository. We could leverage the Rust workspace feature to manage both the library and CLI. The Rust bridge for the GUI could be managed as a separate package. This approach has been implemented in our [NAHPU](https://github.com/hhandika/nahpu) app, which serves as a digital field catalog for natural history collections.
:::
