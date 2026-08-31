Remove-Item -r ./lib/src/rust/api/frb_*
Remove-Item -r ./rust/src/frb_*

Write-Output "Cleaning Flutter build files"
flutter clean

Write-Output "Updating Rust dependencies"
Set-Location rust
cargo update
Set-Location ..

Write-Output "Updating FRB"
cargo install 'flutter_rust_bridge_codegen@2.13.0'

Write-Output "Updating Dart dependencies"
flutter pub upgrade

Write-Output "Generating FRB for Dart"
flutter_rust_bridge_codegen generate
flutter pub run build_runner build --delete-conflicting-outputs
$generatedDart = Join-Path 'lib' (Join-Path 'src' 'rust')
dart fix --apply --code=prefer_const_constructors $generatedDart
dart format $generatedDart

Write-Output "Running Dart fix"
dart fix --apply

Write-Output "Check Rust code"
Set-Location rust
cargo check
Set-Location ..
