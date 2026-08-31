#!/opt/homebrew/bin/fish

set DART_FRB "lib/src/rust/frb_generated.dart"
set DART_FRB_IO "lib/src/rust/frb_generated.io.dart"
set RUST_FRB_IO "rust/src/frb_generated.io.rs"
set RUST_FRB "rust/src/frb_generated.rs"

echo "Removing old FRB files"
rm -f $DART_FRB $DART_FRB_IO $RUST_FRB $RUST_FRB_IO

echo "Cleaning up flutter project"
flutter clean

echo "Updating Rust dependencies"
cd rust
cargo update
cd ..

echo "Updating FRB"
cargo install 'flutter_rust_bridge_codegen@2.13.0'

echo "Updating Dart dependencies"
flutter pub upgrade

echo "Generating FRB for Dart"
flutter_rust_bridge_codegen generate
flutter pub run build_runner build --delete-conflicting-outputs
dart fix --apply --code=prefer_const_constructors lib/src/rust
dart format lib/src/rust

echo "Running Dart fix"
dart fix --apply

echo "Checking Rust code"
cd rust
cargo check
cd ..
