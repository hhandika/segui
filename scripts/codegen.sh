#!/bin/bash
flutter_rust_bridge_codegen \
    -r api/src/api.rs \
    -d lib/bridge_generated.dart \
    -c ios/Runner/bridge_generated.h \
    -e macos/Runner/