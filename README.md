# One Bit Game

A mobile-first pixel platformer prototype built with Flutter and Flame using Kenney's CC0 1-Bit Platformer Pack.

## Current playable foundation

- Landscape mobile layout
- On-screen left, right, and jump controls
- Gravity, jumping, platform collisions, and respawning
- Smooth horizontal camera tracking
- Fixed 192-pixel logical world height for sharp pixel-art scaling
- Kenney transparent packed tilesheet integrated as a Flutter asset

## Run locally

1. Install the current stable Flutter SDK and Android Studio.
2. Clone this repository.
3. From the repository root, generate any missing platform folders:

   ```bash
   flutter create --platforms=android,ios .
   ```

4. Install dependencies:

   ```bash
   flutter pub get
   ```

5. Start an Android emulator or connect a phone with USB debugging enabled.
6. Run:

   ```bash
   flutter run
   ```

## Project direction

The next milestones are animated characters, Tiled map loading, hazards, collectibles, doors, level completion, menus, saves, audio, and Android release configuration.

## Asset license

The included Kenney asset is released under CC0 1.0. See `assets/images/kenney/LICENSE.txt`.
