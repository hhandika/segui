#!/bin/bash
echo "Codegen options:"
PS3='Please select the mode: '
OPT=("Debug" "Release" "Quit")

select mode in "${OPT[@]}"

do
    case $mode in
        "Debug")
            echo "Generating code for Debug..."
            RUST_LOG=debug flutter_rust_bridge_codegen \
                -r segul_api/src/segul_api.rs \
                -d lib/bridge_generated.dart \
                --dart-decl-output lib/bridge_definitions.dart \
                -c ios/Runner/bridge_generated.h \
                -e macos/Runner/
            break
            ;;
        "Release")
            echo "Generating code for Release..."
            flutter_rust_bridge_codegen \
                -r segul_api/src/segul_api.rs \
                -d lib/bridge_generated.dart \
                --dart-decl-output lib/bridge_definitions.dart \
                -c ios/Runner/bridge_generated.h \
                -e macos/Runner/
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $mode";;
    esac
done