# Street Fighter Alpha 2 Recompiled — macOS Edition 3.5

Community macOS launcher for CPS2Recomp. Tested locally on Apple Silicon M4 by the project maintainer on 2026-11-26. This is not an official Capcom product.

Upstream engine: https://github.com/tmcleroy/cps2recomp — the diagnostic recorded commit `20d5a2dd3d50713f4e0a4c091d31fe27c50d803d`. The local close-out script records the actual checkout and its status separately. Consult the upstream license and third-party notices. Game rights belong to their respective owners.

## Source scope
`Launcher.swift` is the approved SwiftUI frontend. It requires a separately prepared CPS2Recomp Motor.app, user-supplied game data, SDL3 and librashader with compatible shader presets. This is a source snapshot, not a standalone game or a complete clean-room build recipe. No ROMs, game binaries, saves, or artwork are published by this package.

Build the frontend on Apple Silicon using Xcode command-line tools:

```sh
xcrun swiftc -parse-as-library -O -target arm64-apple-macos13.0 Launcher.swift -o SFA2ArcadeLauncher
```

Place the executable in a properly configured macOS app bundle. The launcher expects Motor.app, arte.png, portable.txt and local user data beside that bundle. The artwork is supplied locally. The upstream motor settings panel handles advanced video, controller and training settings. The frontend provides quick shader selection. Distribution on other Macs is not yet verified; local builds use ad-hoc signing.
