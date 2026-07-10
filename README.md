# One Bit Escape

A mobile-first one-bit puzzle platformer built with Flutter, Flame, Tiled, and Kenney's CC0 1-Bit Platformer Pack.

## Current playable vertical slice

- Landscape Android-first Flutter app
- Fixed 320 × 192 Flame camera
- Tiled TMX starter level
- Multitouch left, right, and jump controls
- Gravity, collision, coyote time, and jump buffering
- Spikes, collectibles, locked exit, respawning, death counter, pause, replay, and menu UI

## Requirements

- Flutter 3.41.0 or newer
- Dart 3.11.0 or newer
- Android Studio with the Android SDK
- Android device or emulator

## Windows setup

```powershell
git clone https://github.com/tan15hacks/one-bit-game.git
cd one-bit-game
powershell -ExecutionPolicy Bypass -File .\tool\setup.ps1
flutter run
```

The setup script generates the native Android scaffold when it is missing, downloads packages, and runs `flutter doctor`.

## Level editing

Open `assets/tiles/level_01.tmx` in Tiled Map Editor. Keep the 16 × 16 tile size and preserve the `Collisions`, `Hazards`, and `Spawns` object-layer names.

## License

The game code is MIT licensed. Kenney's included artwork is CC0; see `THIRD_PARTY_NOTICES.md`.
