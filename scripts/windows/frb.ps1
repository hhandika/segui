rm -r ./lib/src/rust/api/frb_*
rm -r ./rust/frb_*

echo "Cleaning Flutter build files"
flutter clean

echo "Updating Rust dependencies"
cd rust
cargo update
cd ..

echo "Updating FRB"
cargo install 'flutter_rust_bridge_codegen@^2.0.0-dev.0'

echo "Updating Dart dependencies"
flutter pub upgrade

echo "Generating FRB for Dart"
flutter_rust_bridge_codegen generate

echo "Running Dart fix"
dart fix --apply
