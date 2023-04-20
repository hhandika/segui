#!/bin/bash
flutter_rust_bridge_codegen \
    -r segul_api/src/segul_api.rs \
    -d lib/bridge_generated.dart \
    -c ios/Runner/bridge_generated.h \
    -e macos/Runner/