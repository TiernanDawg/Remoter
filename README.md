# Remoter

A native SwiftUI iPhone remote for Roku devices on your local Wi-Fi network.

## Included features

- Scan the iPhone's current Wi-Fi IPv4 /24 subnet for Roku devices.
- Add a Roku manually by IPv4 address.
- Save multiple devices locally and rename them.
- Directional navigation, select, home, back, playback, and instant replay.
- Volume, mute, power, and Find Remote controls when the Roku reports support.
- Send text to an active Roku on-screen keyboard.
- List and launch installed Roku apps.
- Display connection errors instead of silently ignoring failed commands.

## Requirements

- iOS 16 or newer.
- iPhone and Roku on the same local network.
- Roku awake and reachable on TCP port 8060.
- On Roku OS 14.1 and later, enable Settings → System → Advanced system settings → Control by mobile apps. Exact menu wording can vary by model and software version.

## Roku compatibility and distribution notice

Remoter uses Roku's local External Control Protocol (ECP). Roku's current developer documentation says selected ECP commands require Control by mobile apps to be enabled. Roku also documents restrictions on third-party platforms sending ECP commands and on publishing ECP-sending code in Roku's own Streaming Store. Technical reachability does not guarantee Roku endorsement or App Store approval. Review Roku's current terms and developer documentation before public distribution.

ECP does not expose every physical-remote feature on every model. Volume, mute, power, and Find Remote controls are displayed only when the device-info response reports the corresponding capability. Voice search, private listening, casting, and initial TV setup are not implemented.

## Discovery limitations

The scanner checks the IPv4 /24 subnet associated with the iPhone's Wi-Fi interface. This avoids requiring Apple's special multicast networking entitlement, but it will not discover devices across VLANs, guest-network isolation, unusual subnet layouts, or networks that block local device-to-device traffic. Manual IP entry is included as a fallback.

## Build

This repository uses XcodeGen.

1. Install Xcode 15 or newer.
2. Install XcodeGen: brew install xcodegen
3. Run xcodegen generate from the repository root.
4. Open Remoter.xcodeproj and build for an iPhone or simulator.

A GitHub Actions workflow builds the app without signing and uploads an unsigned IPA artifact. An unsigned IPA is not directly installable; it must be signed with a valid Apple development/distribution certificate and provisioning profile.

## Privacy

Saved device addresses and names are stored locally using UserDefaults. Remoter does not require a Roku account, use analytics, or use a cloud relay. Device discovery and remote commands are sent directly from the iPhone to Roku devices on the local network.

## License

No third-party Roku branding or assets are bundled.