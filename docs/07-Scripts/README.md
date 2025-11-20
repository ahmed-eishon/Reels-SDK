# Scripts Documentation

Documentation for build, development, and workflow scripts in the Reels SDK.

## Documentation Structure

### 📱 [Android](./Android/)
- [Local Scripts](./Android/01-Local-Scripts.md) - Development and AAR build scripts
- [Workflow Scripts](./Android/02-Workflow-Scripts.md) - GitHub Actions release workflows

### 🍎 [iOS](./iOS/)
- Documentation coming soon

---

## Quick Navigation

### Android
- **Local Development:** [`clean-install-android.sh`](./Android/01-Local-Scripts.md#clean-install-androidsh) - Setup folder-based integration
- **AAR Building:** [`build-reels-android-aar.sh`](./Android/01-Local-Scripts.md#build-reels-android-aarsh) - Build debug/release AARs
- **CI/CD:** [GitHub Workflows](./Android/02-Workflow-Scripts.md) - Automated releases

### iOS
- Coming soon

---

## Script Locations

```
scripts/
├── lib/
│   └── common.sh              # Shared utilities (iOS + Android)
├── dev/
│   └── android/
│       └── clean-install-android.sh
├── sdk/
│   ├── android/
│   │   └── build-reels-android-aar.sh
│   └── ios/
│       ├── build-frameworks.sh
│       ├── package-frameworks.sh
│       └── [other iOS scripts]
└── ci/
    ├── create-release-tags.sh
    └── release-ios.sh
```
