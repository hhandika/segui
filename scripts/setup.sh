#!/bin/bash
cargo install flutter_rust_bridge_codegen
flutter pub add --dev ffigen && flutter pub add ffi
cargo install cargo-xcode

