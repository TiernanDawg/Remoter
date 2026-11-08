# Remoter

A native SwiftUI Roku remote for iPhone.

## Highlights

- Gesture trackpad for directional navigation, with a dedicated OK / Select button.
- Back, Home, Menu, playback, volume, power and Find Remote controls when supported by the Roku.
- Four persistent appearances: Midnight Glass, Porcelain, Pure OLED and Neon Pulse.
- Local network Roku discovery, manual IP connection, saved devices, keyboard text entry and installed-channel launching.
- No accounts, ads, analytics or third-party packages.

## Build

The project is generated with XcodeGen from `project.yml`. The GitHub Actions workflow uses the Xcode 27 runner and packages an unsigned IPA for sideloading.

## Roku requirements

The iPhone and Roku must be on the same local network. On Roku OS 14.1 and newer, enable **Settings → System → Advanced system settings → Control by mobile apps → Enabled** for ECP remote commands.

The Picture / Menu control sends Roku's `Info` key; picture-mode availability and menu names depend on the TV model and current Roku software.
