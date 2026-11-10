# UsbCam

Minimal SwiftUI app that shows live video from a USB (UVC) camera, falling back to the built-in camera. iOS 16.0+ deployment target.

## Important: USB camera support depends on iOS version

- Apple only added external (UVC) camera support to AVFoundation in **iOS 17** (`AVCaptureDevice.DeviceType.external`).
- On **iOS 16** the app runs, but only the built-in camera will appear.
- An iPhone 11 can update to iOS 17 or later, so update it to use a USB camera.
- Not every Lightning-to-USB adapter or camera works. Adapters that pass power (the Lightning to USB 3 Camera Adapter) and standard UVC cameras are the best bet. Test with your camera.

## Project layout

- `project.yml` – XcodeGen spec (generates `UsbCam.xcodeproj`)
- `UsbCam/` – Swift sources
- `.github/workflows/build.yml` – GitHub Actions build

## Build locally (Mac)

```
brew install xcodegen
xcodegen generate
open UsbCam.xcodeproj
```

## GitHub Actions

Every push to `main` (or a manual run) builds the app on a macOS runner and uploads `UsbCam-unsigned.ipa` as a build artifact (Actions tab > latest run > Artifacts).

The IPA is **unsigned**. To install on your iPhone, sign and install it with a sideloading tool such as AltStore or Sideloadly (free Apple ID works, apps expire after 7 days), or add your own signing certificate and provisioning profile to the workflow.
